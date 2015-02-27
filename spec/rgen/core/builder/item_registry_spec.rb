require_relative  '../../../spec_helper'

module RGen::Builder
  describe ItemRegistry do
    let(:item_base) do
      RGen::Configuration::Item
    end

    let(:item_factory) do
      RGen::Configuration::ItemFactory
    end

    let(:item_registry) do
      ItemRegistry.new(item_base, item_factory)
    end

    let(:item_entries) do
      item_registry.instance_variable_get(:@entries)
    end

    describe "#register_item" do
      before do
        item_registry.register_item(:foo) do
          define_field :foo
        end
      end

      let(:entry) do
        item_entries[:foo]
      end

      it "#baseを親クラスとしてアイテムクラスを定義し、アイテム名で登録する" do
        expect(entry.klass).to have_attributes(
          superclass: item_registry.base,
          fields:     match([:foo])
        )
      end

      it "#factoryを対応するファクトリとして登録する" do
        expect(entry.factory).to eql item_registry.factory
      end
    end

    describe "#build_factories" do
      before do
        [:foo, :bar, :baz, :qux].each do |name|
          item_registry.register_item(name) do
          end
        end
        item_registry.enable([:foo, :baz])
        item_registry.enable(:qux)
      end

      let(:factories) do
        item_registry.build_factories
      end

      let(:items) do
        factories.each_with_object({}) {|(n, f), h| h[n] = f.create(nil, nil)}
      end

      it "#enableで有効にされたアイテムを生成するファクトリオブジェクトを有効にされた順で生成する" do
        expect(items).to match({
          foo: be_kind_of(item_entries[:foo].klass),
          baz: be_kind_of(item_entries[:baz].klass),
          qux: be_kind_of(item_entries[:qux].klass)
        })
      end

      context "#enableで同一アイテムが複数回有効にされた場合" do
        before do
          item_registry.enable([:qux, :foo])
        end

        specify "2回目以降の有効化を無視して、ファクトリオブジェクトを生成する" do
          expect(items).to match({
            foo: be_kind_of(item_entries[:foo].klass),
            baz: be_kind_of(item_entries[:baz].klass),
            qux: be_kind_of(item_entries[:qux].klass)
          })
        end
      end
    end
  end
end
