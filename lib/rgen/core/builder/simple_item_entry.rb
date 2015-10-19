module RGen
  module Builder
    class SimpleItemEntry
      def initialize(base, factory, *contexts, &body)
        @item_class = Class.new(base)
        @factory    = factory
        @item_class.class_exec(*contexts, &body)  if block_given?
      end

      attr_reader :item_class
      attr_reader :factory

      def build_factory
        f             = @factory.new
        f.target_item = @item_class
        f
      end
    end
  end
end
