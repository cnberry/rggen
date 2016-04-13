simple_item :bit_field, :name do
  register_map do
    field :name

    input_pattern %r{(#{variable_name})}

    build do |cell|
      @name = parse_name(cell)
      error "repeated bit field name: #{@name}" if repeated_name?
    end

    def parse_name(cell)
      if pattern_matched?
        captures.first
      else
        error "invalid value for bit field name: #{cell.inspect}"
      end
    end

    def repeated_name?
      register_block.bit_fields.any? do |bit_field|
        @name == bit_field.name
      end
    end
  end
end
