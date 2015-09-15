module RGen::Builder
  class Category
    def initialize
      @item_registries  = {}
    end

    def append_item_registry(component_name, item_registry)
      return if @item_registries.key?(component_name)
      @item_registries[component_name]  = item_registry
      define_registry_method(component_name)
    end

    def register_item(item_name, &body)
      @current_item_name  = item_name
      instance_exec(&body)
      @current_item_name  = nil
    end

    def enable(item_or_items)
      @item_registries.each_value do |item_registry|
        item_registry.enable(item_or_items)
      end
    end

    private

    def define_registry_method(component_name)
      define_singleton_method(component_name) do |&body|
        @item_registries[component_name].register_item(@current_item_name, &body)
      end
    end
  end
end
