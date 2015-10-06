module RGen::RegisterMap::Base
  class ItemFactory < RGen::InputBase::ItemFactory
    def create(component, configuration, cell = nil)
      item  = create_item(component, cell)
      item.build(configuration, cell)
      item
    end

    private

    def error(message, cell)
      fail RGen::RegisterMapError.new(message, cell.position)
    end
  end
end
