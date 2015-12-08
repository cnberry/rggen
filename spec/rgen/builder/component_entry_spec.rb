require_relative  '../../spec_helper'

module RGen::Builder
  describe ComponentEntry do
    let(:component_base) do
      RGen::InputBase::Component
    end

    let(:component_base_factory) do
      RGen::InputBase::ComponentFactory
    end

    let(:item_base_base) do
      RGen::InputBase::Item
    end

    let(:item_base_factory) do
      RGen::InputBase::ItemFactory
    end

    let(:modules) do
      [Module.new, Module.new]
    end

    let(:entry) do
      ComponentEntry.new
    end

    let(:entries) do
      [ComponentEntry.new, ComponentEntry.new]
    end

    describe "#component_class" do
      context "クラスが与えられた場合" do
        it "与えられたクラスをコンポーネントクラスとして登録する" do
          entry.component_class(component_base)
          expect(entry.component_class).to be component_base
        end
      end

      context "ベースクラスとブロックが与えられた場合" do
        it "与えられたクラスを親クラスとしてコンポーネントクラスを定義する" do
          entry.component_class(component_base) do
            def foo ; end
          end
          aggregate_failures do
            expect(entry.component_class.superclass                    ).to be component_base
            expect(entry.component_class.public_instance_methods(false)).to match [:foo]
          end
        end
      end

      context "ベースクラスとオプションとしてインクルードするモジュールが与えられた場合" do
        it "与えられたクラスを親クラスとしてコンポーネントクラスを定義する" do
          entry.component_class(component_base, include: modules[0])
          expect(entry.component_class.superclass).to be component_base
        end

        it "与えたモジュールをコンポーネントクラスにMix-inする" do
          entries[0].component_class(component_base, include: modules[0])
          entries[1].component_class(component_base, include: [modules[0], modules[1]])
          expect(entries[0].component_class.included_modules).to include(modules[0])
          expect(entries[1].component_class.included_modules).to include(modules[0])
          expect(entries[1].component_class.included_modules).to include(modules[1])
        end
      end
    end

    describe "#component_factory" do
      context "クラスが与えられた場合" do
        it "与えられたクラスをコンポーネントファクトリクラスとして登録する" do
          entry.component_factory(component_base_factory)
          expect(entry.component_factory).to be component_base_factory
        end
      end

      context "ベースクラスとブロックが与えられた場合" do
        it "与えられたクラスを親クラスとしてコンポーネントファクトリクラスを定義する" do
          entry.component_factory(component_base_factory) do
            def foo ; end
          end
          aggregate_failures do
            expect(entry.component_factory.superclass                    ).to be component_base_factory
            expect(entry.component_factory.public_instance_methods(false)).to match [:foo]
          end
        end
      end

      context "ベースクラスとオプションとしてインクルードするモジュールが与えられた場合" do
        it "与えられたクラスを親クラスとしてコンポーネントファクトリクラスを定義する" do
          entry.component_factory(component_base_factory, include: modules[0])
          expect(entry.component_factory.superclass).to be component_base_factory
        end

        it "与えたモジュールをコンポーネントファクトリクラスにMix-inする" do
          entries[0].component_factory(component_base_factory, include: modules[0])
          entries[1].component_factory(component_base_factory, include: [modules[0], modules[1]])
          expect(entries[0].component_factory.included_modules).to include(modules[0])
          expect(entries[1].component_factory.included_modules).to include(modules[0])
          expect(entries[1].component_factory.included_modules).to include(modules[1])
        end
      end
    end

    describe "#item_base" do
      context "クラスが与えられた場合" do
        it "与えられたクラスをアイテムベースクラスとして登録する" do
          entry.item_base(item_base_base)
          expect(entry.item_base).to be item_base_base
        end
      end

      context "ベースクラスとブロックが与えられた場合" do
        it "与えられたクラスを親クラスとしてアイテムベースクラスを定義する" do
          entry.item_base(item_base_base) do
            def foo ; end
          end
          aggregate_failures do
            expect(entry.item_base.superclass                    ).to be item_base_base
            expect(entry.item_base.public_instance_methods(false)).to match [:foo]
          end
        end
      end

      context "ベースクラスとオプションとしてインクルードするモジュールが与えられた場合" do
        it "与えられたクラスを親クラスとしてアイテムベースクラスを定義する" do
          entry.item_base(item_base_base, include: modules[0])
          expect(entry.item_base.superclass).to be item_base_base
        end

        it "与えたモジュールをアイテムベースクラスにMix-inする" do
          entries[0].item_base(item_base_base, include: modules[0])
          entries[1].item_base(item_base_base, include: [modules[0], modules[1]])
          expect(entries[0].item_base.included_modules).to include(modules[0])
          expect(entries[1].item_base.included_modules).to include(modules[0])
          expect(entries[1].item_base.included_modules).to include(modules[1])
        end
      end
    end

    describe "#item_factory" do
      context "クラスが与えられた場合" do
        it "与えられたクラスをアイテムファクトリとして登録する" do
          entry.item_factory(item_base_factory)
          expect(entry.item_factory).to be item_base_factory
        end
      end

      context "ベースクラスとブロックが与えられた場合" do
        it "与えられたクラスを親クラスとしてアイテムファクトリクラスを定義する" do
          entry.item_factory(item_base_factory) do
            def foo ; end
          end
          aggregate_failures do
            expect(entry.item_factory.superclass                    ).to be item_base_factory
            expect(entry.item_factory.public_instance_methods(false)).to match [:foo]
          end
        end
      end

      context "ベースクラスとオプションとしてインクルードするモジュールが与えられた場合" do
        it "与えられたクラスを親クラスとしてアイテムベースクラスを定義する" do
          entry.item_factory(item_base_factory, include: modules[0])
          expect(entry.item_factory.superclass).to be item_base_factory
        end

        it "与えたモジュールをアイテムベースクラスにMix-inする" do
          entries[0].item_factory(item_base_factory, include: modules[0])
          entries[1].item_factory(item_base_factory, include: [modules[0], modules[1]])
          expect(entries[0].item_factory.included_modules).to include(modules[0])
          expect(entries[1].item_factory.included_modules).to include(modules[0])
          expect(entries[1].item_factory.included_modules).to include(modules[1])
        end
      end
    end

    describe "#build_factory" do
      before do
        entry.component_class(component_base)
        entry.component_factory(component_base_factory) do
          def create_active_items(component, data)
            active_item_factories.each do |name, factory|
              create_item(factory, configuration, data)
            end
          end

          def load(file)
          end
        end
      end

      let(:factory) do
        f = entry.build_factory
        f.root_factory
        f
      end

      let(:component) do
        factory.create
      end

      context "アイテムを持たないとき" do
        it "アイテムを含まないコンポーネントオブジェクトを生成するファクトリを返す" do
          expect(component).to be_kind_of(entry.component_class)
          expect(component.fields).to be_empty
        end
      end

      context "アイテムを持つとき" do
        before do
          entry.item_base(item_base_base)
          entry.item_factory(item_base_factory)
          [:foo, :bar].each do |item_name|
            entry.item_store.define_simple_item(nil, item_name) do
              field item_name, default: item_name
            end
            entry.item_store.enable(item_name)
          end
        end

        it "有効になったアイテムを含むコンポーネントオブジェクトを生成するファクトリを返す" do
          expect(component).to be_kind_of(entry.component_class)
          expect(component.fields).to match([:foo, :bar])
        end
      end
    end
  end
end
