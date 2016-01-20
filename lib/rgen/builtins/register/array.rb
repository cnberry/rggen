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
    export :index
    export :local_index
    export :loop_variables
    export :loop_variable

    def index
      (register.array? && "#{base_index}+#{local_index}") || base_index
    end

    def local_index
      return nil unless register.array?
      local_index_terms(0).join('+')
    end

    def loop_variables
      return nil unless register.array?
      register.dimensions.size.times.map { |l| loop_variable(l) }
    end

    def loop_variable(level)
      return nil unless register.array? && level < register.dimensions.size
      @loop_variables ||= Hash.new do |h, l|
        h[l]  = create_identifier("g_#{loop_index(l)}")
      end
      @loop_variables[level]
    end

    def base_index
      previous_registers.map(&:count).sum(0)
    end

    def local_index_terms(level)
      if level < (register.dimensions.size - 1)
        partial_count = register.dimensions[(level + 1)..-1].inject(:*)
        term          = [partial_count, '*', loop_variable(level)].join
        local_index_terms(level + 1).unshift(term)
      else
        [loop_variable(level)]
      end
    end

    def loop_index(level)
      level.times.with_object('i') { |_, index| index.next! }
    end

    def previous_registers
      register_block.registers.take_while { |r| !register.equal?(r) }
    end

    generate_pre_code :module_item do |buffer|
      register.dimensions.each_with_index do |dimension, level|
        generate_for_begin_code(dimension, level, buffer)
      end if register.array?
    end

    generate_post_code :module_item do |buffer|
      register.dimensions.size.times do
        generate_for_end_code(buffer)
      end if register.array?
    end

    def generate_for_begin_code(dimension, level, buffer)
      buffer << generate_for_header(dimension, level)
      buffer << ' begin : '
      buffer << block_name(level)
      buffer << nl
      buffer.indent += 2
    end

    def generate_for_end_code(buffer)
      buffer.indent -= 2
      buffer << 'end' << nl
    end

    def generate_for_header(dimension, level)
      genvar  = loop_variable(level)
      "for (genvar #{genvar} = 0;#{genvar} < #{dimension};#{genvar}++)"
    end

    def block_name(level)
      "gen_#{register.name}_#{level}"
    end
  end
end
