require_relative  '../../../spec_helper'

module RGen::Builder
  describe ListItemEntry do
    let(:item_base) do
      RGen::InputBase::Item
    end

    let(:factory_base) do
      RGen::InputBase::ItemFactory
    end

    let(:list_item_entry) do
      ListItemEntry.new(item_base, factory_base)
    end

    let(:list_item_entry_with_shared_context) do
      ListItemEntry.new(item_base, factory_base, shared_context)
    end

    let(:items) do
      list_item_entry.instance_variable_get(:@items)
    end

    let(:shared_context) do
      Object.new
    end

    let(:component) do
      RGen::InputBase::Component.new
    end

    describe "#initialize" do
      context "ブロックが与えられた場合" do
        specify "ブロックを自身のコンテキストで実行する" do
          entry1  = nil
          entry2  = ListItemEntry.new(item_base, factory_base) do
            entry1  = self
          end

          expect(entry1).to eql entry2
        end
      end

      context "コンテキストオブジェクトが与えられたとき" do
        it "共有コンテキストを返す#shared_contextを定義する" do
          expect(list_item_entry_with_shared_context.send(:shared_context)).to eql shared_context
        end
      end
    end

    describe "#item_base" do
      it "生成時に与えたitem_baseを親クラスとするベースアイテムクラスを返す" do
        expect(list_item_entry.item_base.superclass).to be item_base
      end

      context "ブロックを与えたとき" do
        before do
          list_item_entry.item_base do
            def foo
            end
          end
        end

        it "ブロックをベースアイテムクラスのコンテキストで実行する" do
          expect(list_item_entry.item_base).to be_method_defined(:foo)
        end
      end

      context "属するエントリが共有コンテキストを持つ場合" do
        specify "ベースアイテムクラスは#shared_contextを持ち、共有コンテキストオブジェクトを返す" do
          item  = list_item_entry_with_shared_context.item_base.new(component)
          expect(item.send(:shared_context)).to eql shared_context
        end
      end
    end

    describe "#factory" do
      it "生成時に与えたfactory_baseを親クラスとするアイテムファクトリクラスを返す" do
        expect(list_item_entry.factory.superclass).to be factory_base
      end

      context "ブロックを与えたとき" do
        before do
          list_item_entry.factory do
            def foo
            end
          end
        end

        it "ブロックをアイテムファクトリクラスのコンテキストで実行する" do
          expect(list_item_entry.factory).to be_method_defined(:foo)
        end
      end

      context "属するエントリが共有コンテキストを持つ場合" do
        specify "アイテムファクトリクラスは#shared_contextを持ち、共有コンテキストオブジェクトを返す" do
          factory = list_item_entry_with_shared_context.factory.new
          expect(factory.send(:shared_context)).to eql shared_context
        end
      end
    end

    describe "#define_list_item" do
      it "#item_baseを親クラスとしてアイテムクラスを定義し、与えたアイテム名で登録する" do
        list_item_entry.define_list_item(:foo) do
          field :foo
        end

        expect(items[:foo]).to have_attributes(
          superclass: list_item_entry.item_base,
          fields:     match([:foo])
        )
      end

      context "コンテキストオブジェクトが与えられたとき" do
        let(:item) do
          list_item_entry.define_list_item(:foo, shared_context) {}
          items[:foo].new(component)
        end

        it "共有コンテキストを返す#shared_contextを定義する" do
          expect(item.send(:shared_context)).to eql shared_context
        end

        context "ベースクラスが既に共有コンテキストを持つ場合" do
          it "RGen::BuilderErrorを発生させる" do
            expect {
              list_item_entry_with_shared_context.define_list_item(:foo, shared_context) {}
            }.to raise_error RGen::BuilderError, "base class already has #shared_context"
          end
        end
      end
    end

    describe "#build_factory" do
      before do
        list_item_entry.factory do
          def select_target_item(arg)
            fail unless @target_items.key?(arg)
            @target_items[arg]
          end
        end

        list_item_entry.define_list_item(:foo) do
        end
        list_item_entry.define_list_item(:bar) do
        end
        list_item_entry.define_list_item(:baz) do
        end
        list_item_entry.define_list_item(:qux) do
        end

        list_item_entry.enable([:qux, :baz])
        list_item_entry.enable(:foo)
      end

      let(:factory) do
        list_item_entry.build_factory
      end

      it "アイテムファクトリオブジェクトを返す" do
        expect(factory).to be_kind_of list_item_entry.factory
      end

      specify "ファクトリオブジェクトは#enableで有効になったアイテムを生成できる" do
        expect(factory.create(nil, :foo)).to be_kind_of items[:foo]
        expect(factory.create(nil, :baz)).to be_kind_of items[:baz]
        expect(factory.create(nil, :qux)).to be_kind_of items[:qux]
      end

      specify "ファクトリオブジェクトは#enableで有効にされなかったアイテムは生成できない" do
        expect {factory.create(nil, :bar)}.to raise_error RuntimeError
      end
    end
  end
end
