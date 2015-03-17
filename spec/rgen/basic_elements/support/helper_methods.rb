def match_address_width(width)
  have_attributes(address_width: width)
end

def match_data_width(width)
  byte_width  = width / 8
  have_attributes(data_width: width, byte_width: byte_width)
end

def match_name(name)
  have_attributes(name: name)
end

def match_base_address(start_address, end_address)
  have_attributes(start_address: start_address, end_address: end_address)
end

def clear_enabled_items
  RGen.generator.builder.categories.each_value do |category|
    category.instance_variable_get(:@item_registries).each_value do |item_registry|
      item_registry.instance_variable_get(:@enabled_items).clear
    end
  end
end
