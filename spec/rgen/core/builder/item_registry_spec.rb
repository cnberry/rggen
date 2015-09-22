require_relative  '../../../spec_helper'

module RGen::Builder
  describe ItemRegistry do
    let(:item_base) do
      RGen::InputBase::Item
    end

    let(:item_factory) do
      RGen::InputBase::ItemFactory
    end

    let(:item_registry) do
      ItemRegistry.new(item_base, item_factory)
    end

    let(:value_item_entries) do
      item_registry.instance_variable_get(:@value_item_entries)
    end

    let(:list_item_entries) do
      item_registry.instance_variable_get(:@list_item_entries)
    end

    let(:enabled_items) do
      item_registry.instance_variable_get(:@enabled_items)
    end

    describe "#register_value_item" do
      before do
        item_registry.register_value_item(:foo) do
          field :foo
        end
      end

      let(:entry) do
        value_item_entries[:foo]
      end

      it "#baseを親クラスとしてアイテムクラスを定義し、アイテム名で登録する" do
        expect(entry.item_class).to have_attributes(
          superclass: item_registry.base,
          fields:     match([:foo])
        )
      end

      it "#factoryを対応するファクトリとして登録する" do
        expect(entry.factory).to eql item_registry.factory
      end

      context "同名の値型アイテムエントリがすでに登録されている場合" do
        it "新しい値型アイテムエントリに差し替える" do
          new_item_class  = nil
          item_registry.register_value_item(:foo) do
            new_item_class  = self
          end

          expect(entry.item_class).to eql new_item_class
        end
      end

      context "同名のリスト型アイテムエントリがすでに登録されている場合" do
        before do
          item_registry.register_list_item(:bar) do
          end
        end

        it "既存のリスト型アイテムエントリを削除する" do
          expect {
            item_registry.register_value_item(:bar) {}
          }.to change {list_item_entries.key?(:bar)}.from(true).to(false)
        end
      end
    end

    describe "#register_list_item" do
      context "引数がリスト名とブロックのとき" do
        let(:entry) do
          list_item_entries[:foo]
        end

        it "リストアイテムエントリを生成し、与えたリスト名で登録する" do
          item_registry.register_list_item(:foo) do
          end
          expect(entry).to be_kind_of RGen::Builder::ListItemEntry
          expect(entry.item_base).to be < item_registry.base
          expect(entry.factory  ).to be < item_registry.factory
        end

        specify "与えたブロックはリストアイテムエントリ内で実行される" do
          e = nil
          item_registry.register_list_item(:foo) do
            e = self
          end

          expect(entry).to be e
        end

        context "同名のリスト型アイテムエントリがすでに登録されている場合" do
          before do
            item_registry.register_list_item(:foo) do
            end
          end

          it "新しいリスト型アイテムエントリに差し替える" do
            new_entry = nil
            item_registry.register_list_item(:foo) do
              new_entry = self
            end

            expect(entry).to eql new_entry
          end
        end

        context "同名の値型アイテムエントリがすでに登録されている場合" do
          before do
            item_registry.register_value_item(:foo) do
            end
          end

          it "既存の値型アイテムエントリを削除する" do
            expect{
              item_registry.register_list_item(:foo) {}
            }.to change {value_item_entries.key?(:foo)}.from(true).to(false)
          end
        end
      end

      context "引数がリスト名、アイテム名、ブロックのとき" do
        before do
          item_registry.register_list_item(:foo) do
          end
        end

        let(:item_name) do
          :bar
        end

        let(:body) do
          proc {}
        end

        it "エントリオブジェクトの#register_list_itemを呼び出して、アイテムの追加を行う" do
          expect(list_item_entries[:foo]).to receive(:register_list_item).with(item_name).and_call_original
          item_registry.register_list_item(:foo, item_name, &body)
        end
      end
    end

    describe "#enable" do
      before do
        item_registry.register_value_item(:foo) {}
        item_registry.register_value_item(:bar) {}
        item_registry.register_list_item(:baz) {}
        item_registry.register_list_item(:qux) {}
      end

      context "引数がアイテム名またはアイテム名の配列のとき" do
        it "enabled_itemsに与えられたアイテム名を与え順番で追加する" do
          item_registry.enable(:bar)
          item_registry.enable([:qux, :foo])
          expect(enabled_items).to match [:bar, :qux, :foo]
        end

        it "すでに有効にされたアイテムは無視する" do
          item_registry.enable(:bar)
          item_registry.enable([:qux, :bar])
          item_registry.enable(:qux)
          expect(enabled_items).to match [:bar, :qux]
        end

        it "登録されていないアイテムは無視する" do
          item_registry.enable(:bar)
          item_registry.enable([:qux, :foobar])
          item_registry.enable(:quux)
          expect(enabled_items).to match [:bar, :qux]
        end
      end

      context "引数がリスト名と、アイテム名またはアイテム名の配列のとき" do
        it "リスト名で指定されているリスト型アイテムエントリオブジェクトの#enableを呼び出し、リストアイテムの有効化を行う" do
          expect(list_item_entries[:baz]).to receive(:enable).with(:foo)
          expect(list_item_entries[:baz]).to receive(:enable).with([:bar, :baz])
          item_registry.enable(:baz, :foo)
          item_registry.enable(:baz, [:bar, :baz])
        end
      end
    end

    describe "#build_factories" do
      before do
        [:foo, :bar].each do |name|
          item_registry.register_value_item(name) do
          end
        end
        [:baz, :qux].each do |name|
          item_registry.register_list_item(name) do
          end
        end
        item_registry.enable([:foo, :baz])
        item_registry.enable(:qux)
      end

      it "#enableで有効にされたアイテムエントリの#build_factoryを有効にされて順で呼び出し、アイテムファクトリオブジェクトを生成する" do
        [:foo, :baz, :qux].each do |item_name|
          entry = value_item_entries[item_name] || list_item_entries[item_name]
          expect(entry).to receive(:build_factory).ordered.and_call_original
        end
        item_registry.build_factories
      end

      it "アイテム名をキーとする、アイテムファクトリオブジェクトハッシュを返す" do
        factories = {}
        [:foo, :baz, :qux].each do |item_name|
          entry = value_item_entries[item_name] || list_item_entries[item_name]
          allow(entry).to receive(:build_factory).and_wrap_original do |m, *args|
            factories[item_name]  = m.call(*args)
            factories[item_name]
          end
        end

        expect(item_registry.build_factories).to match factories
      end
    end
  end
end
