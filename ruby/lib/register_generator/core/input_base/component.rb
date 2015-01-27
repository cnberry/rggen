module RegisterGenerator::InputBase
  class Component < Base::Component
    def append_item(item)
      super(item)
      item.fields.each do |field|
        define_singleton_method(field) do
          item.__send__(field)
        end
      end
    end
  end
end
