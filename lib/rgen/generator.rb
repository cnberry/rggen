module RGen
  class Generator
    class << self
      Option = Struct.new(:short, :long, :description)

      def options
        @options  ||= {}
      end

      private

      def add_option(option_name, &body)
        options[option_name]  = Option.new
        body.call(options[option_name])
      end
    end

    add_option :setup do |option|
      option.long = '--setup FILE'
    end

    add_option :configuration do |option|
      option.short  = '-c'
      option.long   = '--configuration FILE'
    end

    def run(argv)
      options = parse_options(argv)
      load_setup(options[:setup])
      configuration = load_configuration(options[:configuration])
      register_map  = load_register_map(configuration, argv.first)
    end

    private

    def parse_options(argv)
      options = {}
      option_parser(options).parse!(argv)
      options
    end

    def option_parser(options)
      OptionParser.new do |parser|
        parser.version      = RGen::VERSION
        parser.program_name = 'rgen'
        add_option_switches(parser, options)
      end
    end

    def add_option_switches(parser, options)
      self.class.options.each do |name, option|
        parser.on(*option.values.compact) do |v|
          options[name] = v
        end
      end
    end

    def load_setup(file)
      file  ||= File.join(RGEN_HOME, 'setup', 'default.rb')
      load(file)
    end

    def build_factory(component_name)
      RGen.builder.build_factory(component_name)
    end

    def load_configuration(file)
      build_factory(:configuration).create(file)
    end

    def load_register_map(configuration, file)
      build_factory(:register_map).create(configuration, file)
    end
  end
end
