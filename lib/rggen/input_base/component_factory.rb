module RgGen
  module InputBase
    class ComponentFactory < Base::ComponentFactory
      attr_writer :loaders

      def create(*args)
        if @root_factory
          file    = args.pop
          source  = load(file)
          args    << source

          component = super(*args)
          component.validate
        else
          component = super(*args)
        end
        component
      end

      private

      def create_items(component, *sources)
        create_active_items(component, sources.last)
        create_passive_items(component)
      end

      def create_passive_items(component)
        passive_item_factories.each do |factory|
          create_item(factory, component)
        end
      end

      def active_item_factories
        @item_factories.each_with_object({}) do |(name, factory), factories|
          factories[name] = factory if factory.active_item_factory?
        end
      end

      def passive_item_factories
        @item_factories.each_value.select(&:passive_item_factory?)
      end

      def load(file)
        load_file(file)
      end

      def load_file(file)
        find_loader(file).load(file)
      end

      def find_loader(file)
        @loaders.find { |l| l.acceptable?(file) } || (
          raise RgGen::LoadError, "unsupported file type -- #{file}"
        )
      end
    end
  end
end
