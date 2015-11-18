module RGen
  module Builder
    class SimpleItemEntry
      def initialize(base, factory, context = nil, &body)
        @item_class = define_item_class(base, context, body)
        @factory    = factory
      end

      attr_reader :item_class
      attr_reader :factory

      def build_factory
        f             = @factory.new
        f.target_item = @item_class
        f
      end

      private

      def define_item_class(base, context, body)
        klass = Class.new(base)
        klass.class_exec do
          define_method(:shared_context) do
            context
          end
          private :shared_context
        end unless context.nil?
        klass.class_exec(&body) unless body.nil?
        klass
      end
    end
  end
end
