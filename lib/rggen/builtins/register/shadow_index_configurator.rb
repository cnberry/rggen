simple_item :register, :shadow_index_configurator do
  ral do
    available? do
      register.shadow?
    end

    generate_code :reg_model_item do
      function_definition :configure_shadow_indexes do |f|
        f.return_type :void
        f.body { |code| function_body(code) }
      end
    end

    def function_body(code)
      register.shadow_indexes.each do |shadow_index|
        code << subroutine_call(:set_shadow_index, arguments(shadow_index))
        code << semicolon
        code << nl
      end
    end

    def arguments(shadow_index)
      [
        parent_name(shadow_index),
        index_name(shadow_index),
        index_value(shadow_index)
      ]
    end

    def parent_name(shadow_index)
      parent_register = fild_parent_register(shadow_index.name)
      string(parent_register.name)
    end

    def fild_parent_register(index_name)
      register_block.bit_fields.find_by(name: index_name).register
    end

    def index_name(shadow_index)
      string(shadow_index.name)
    end

    def index_value(shadow_index)
      if shadow_index.value
        shadow_index.value
      else
        "indexes[#{array_index}]"
      end
    end

    def array_index
      @array_index  ||= -1
      @array_index  += 1
    end
  end
end
