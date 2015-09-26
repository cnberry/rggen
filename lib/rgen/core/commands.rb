module RGen
  module Commands
    extend Forwardable

    def generator
      @generator  ||= RGen::Generator.new
    end

    [
      [:component_registry, :component_registry],
      [:define_value_item , :value_item        ],
      [:define_list_item  , :list_item         ],
      [:enable            , :enable            ],
      [:register_loader   , :loader            ]
    ].each do |method_name, alias_name|
      def_delegator('generator.builder', method_name, alias_name)
    end
  end

  extend Commands
end
