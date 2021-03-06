list_item :register, :type, :external do
  register_map do
    read_write
    required_byte_size any_size
    need_no_bit_fields
  end

  rtl do
    build do
      interface_port :register_block, :bus_if,
                     name:    "#{register.name}_bus_if",
                     type:    :rggen_bus_if,
                     modport: :master
    end

    generate_code_from_template :register
  end

  c_header do
    delegate [:name, :byte_size] => :register

    address_struct_member do
      "RGGEN_EXTERNAL_REGISTERS(#{byte_size}, #{name.upcase}) #{name}"
    end
  end
end
