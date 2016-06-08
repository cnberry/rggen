module RgGen
  module OutputBase
    module VerilogUtility
      class Declaration
        def initialize(declation_type, attributes)
          @declation_type = declation_type
          @attributes     = attributes
        end

        def to_s
          code_snippets.join(' ')
        end

        private

        def code_snippets
          [
            random_or_direction_or_parameter_type,
            data_type,
            width,
            identifier,
            default_value_assignment
          ].select(&:itself)
        end

        def random_or_direction_or_parameter_type
          {
            variable:  @attributes[:random] && :rand,
            port:      @attributes[:direction],
            parameter: @attributes[:parameter_type]
          }[@declation_type]
        end

        def data_type
          @attributes[:data_type]
        end

        def width
          return unless vector?
          "[#{(@attributes[:width] || 1) - 1}:0]"
        end

        def identifier
          "#{@attributes[:name]}#{dimensions}"
        end

        def dimensions
          return if @attributes[:dimensions].nil?
          @attributes[:dimensions].map { |dimension| "[#{dimension}]" }.join
        end

        def default_value_assignment
          return if @attributes[:default].nil?
          "= #{@attributes[:default]}"
        end

        def parameter?
          @declation_type == :parameter
        end

        def vector?
          return true if @attributes[:vector]
          @attributes[:width] && (parameter? || (@attributes[:width] > 1))
        end
      end
    end
  end
end
