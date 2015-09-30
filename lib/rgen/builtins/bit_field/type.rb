RGen.list_item(:bit_field, :type) do
  register_map do
    item_base do
      define_helpers do
        def read_write
          @readable = true
          @writable = true
        end

        def read_only
          @readable = true
          @writable = false
        end

        def write_only
          @readable = false
          @writable = true
        end

        def reserved
          @readable = false
          @writable = false
        end

        def readable
          @readable.nil? || @readable
        end

        def writable
          @writable.nil? || @writable
        end

        attr_setter :required_width
      end

      field :type
      field :readable?
      field :writable?
      field :read_only?
      field :write_only?
      field :reserved?

      build do |cell|
        @type       = cell.to_sym.downcase
        @readable   = object_class.readable
        @writable   = object_class.writable
        @read_only  =  @readable && !@writable
        @write_only = !@readable &&  @writable
        @reserved   = !@readable && !@writable
      end

      validate do
        case
        when mismatch_width?
          error "#{object_class.required_width} bit(s) width required:" \
                " #{bit_field.width} bit(s)"
        end
      end

      def mismatch_width?
        return false if object_class.required_width.nil?
        return false if bit_field.width == object_class.required_width
        true
      end
    end

    factory do
      def select_target_item(cell)
        type  = cell.value.to_sym.downcase
        @target_items.fetch(type) do
          error "unknown bit field type: #{type}", cell
        end
      end
    end
  end
end
