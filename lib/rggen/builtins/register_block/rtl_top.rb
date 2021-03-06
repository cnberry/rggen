define_simple_item :register_block, :rtl_top do
  rtl do
    write_file '<%= register_block.name %>.sv' do |f|
      f.body { source_file_body }
    end

    def source_file_body
      module_definition register_block.name do |m|
        m.parameters register_block.parameter_declarations(:register_block)
        m.ports      register_block.port_declarations(:register_block)
        m.signals    register_block.signal_declarations(:register_block)
        m.body { |code| module_body(code) }
      end
    end

    def module_body(code)
      register_block.generate_code(:register_block, :top_down, code)
    end

    generate_pre_code :register_block do
      process_template
    end

    generate_post_code :register_block do
      :'`undef rggen_connect_bit_field_if'
    end
  end
end
