list_item :bit_field, :type, [:w0c, :w1c] do
  register_map do
    read_write
    need_initial_value
    use_reference width: same_width
    irq? { bit_field.has_reference? }
  end

  rtl do
    delegate [:name, :type] => :bit_field

    build do
      input :register_block, :set,
            name: "i_#{name}_set",
            width: width,
            dimensions: dimensions
    end

    generate_code_from_template :register

    def initial_value
      hex(bit_field.initial_value, width)
    end

    def clear_value
      { w0c: 0, w1c: 1 }[type]
    end
  end
end
