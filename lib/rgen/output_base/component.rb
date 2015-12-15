module RGen
  module OutputBase
    class Component < Base::Component
      include Base::HierarchicalAccessors

      def initialize(parent, configuration, register_map)
        super(parent)
        define_hierarchical_accessors
        @configuration  = configuration
        @register_map   = register_map
        def_delegators(:@register_map, *@register_map.fields)
      end

      attr_reader :configuration

      def build
        items.each(&:build)
        children.each(&:build)
      end

      def generate_code(kind, mode, buffer = nil)
        output_code = buffer.nil?
        buffer      = buffer || []
        generate_code_main(kind, mode, buffer)
        buffer.join if output_code
      end

      def write_file(output_directory = '.')
        FileUtils.mkpath(output_directory) unless Dir.exist?(output_directory)
        items.each do |item|
          item.write_file(output_directory)
        end
        children.each do |child|
          child.write_file(output_directory)
        end
      end

      private

      def generate_code_main(kind, mode, buffer)
        case mode
        when :top_down
          generate_item_code(kind, buffer)
          generate_child_code(kind, mode, buffer)
        when :bottom_up
          generate_child_code(kind, mode, buffer)
          generate_item_code(kind, buffer)
        end
      end

      def generate_child_code(kind, mode, buffer)
        children.each do |child|
          child.generate_code(kind, mode, buffer)
        end
      end

      def generate_item_code(kind, buffer)
        items.each do |item|
          item.generate_code(kind, buffer)
        end
      end
    end
  end
end