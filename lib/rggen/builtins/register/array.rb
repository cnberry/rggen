simple_item :register, :array do
  register_map do
    field :array?
    field :dimensions
    field :count

    input_pattern %r{\[(#{number}(?:,#{number})*)\]},
                  match_automatically: false

    build do |cell|
      @dimensions = parse_array_dimensions(cell)
      @array      = @dimensions.not_nil?
      @count      = (@dimensions && @dimensions.inject(&:*)) || 1
      if @dimensions && @dimensions.any?(&:zero?)
        error "0 is not allowed for array dimension: #{cell.inspect}"
      end
    end

    validate do
      case
      when multi_dimensions_array_with_real_register?
        error 'not use multi dimensions array with real register'
      when mismatch_with_own_byte_size?
        error "mismatches with own byte size(#{register.byte_size}):" \
              " #{dimensions}"
      end
    end

    def parse_array_dimensions(cell)
      case
      when cell.nil? || cell.empty?
        nil
      when pattern_match(cell)
        captures.first.split(',').map(&method(:Integer))
      else
        error "invalid value for array dimension: #{cell.inspect}"
      end
    end

    def multi_dimensions_array_with_real_register?
      return false unless array?
      return false if register.shadow?
      register.multiple? && dimensions.size > 1
    end

    def mismatch_with_own_byte_size?
      return false unless array?
      return false if register.shadow?
      register.byte_size != dimensions.first * configuration.byte_width
    end
  end

  rtl do
    export :loop_variables
    export :loop_variable

    def loop_variables
      return nil unless register.array?
      Array.new(register.dimensions.size) { |l| loop_variable(l) }
    end

    def loop_variable(level)
      return nil unless register.array? && level < register.dimensions.size
      @loop_variables ||= Hash.new do |h, l|
        h[l]  = create_identifier("g_#{loop_index(l)}")
      end
      @loop_variables[level]
    end

    generate_pre_code :module_item do |code|
      if register.array?
        generate_header(code)
        generate_for_headers(code)
      end
    end

    generate_post_code :module_item do |code|
      if register.array?
        generate_for_footers(code)
        generate_footer(code)
      end
    end

    def generate_header(code)
      code << "generate if (1) begin : g_#{register.name}" << nl
      code.indent += 2
      code << "genvar #{loop_variables.join(', ')};" << nl
    end

    def generate_for_headers(code)
      register.dimensions.each_with_index do |dimension, level|
        code << generate_for_header(dimension, level) << nl
        code.indent += 2
      end
    end

    def generate_for_header(dimension, level)
      gv  = loop_variable(level)
      "for (#{gv} = 0;#{gv} < #{dimension};#{gv}++) begin : g"
    end

    def generate_for_footers(code)
      register.dimensions.size.times do
        code.indent -= 2
        code << :end << nl
      end
    end

    def generate_footer(code)
      code.indent -= 2
      code << :end << space << :endgenerate << nl
    end
  end
end
