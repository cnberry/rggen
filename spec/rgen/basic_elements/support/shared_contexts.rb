shared_context 'configuration common' do
  class ConfigurationDummyLoader < RGen::InputBase::Loader
    self.supported_types  = [:txt]

    def self.load_data(data = nil)
      @load_data  = data  if data
      @load_data
    end

    def self.clear
      @load_data  = nil
    end

    def load_file(file)
      self.class.load_data
    end
  end

  def build_configuration_factory
    f         = RGen.generator.builder.build_factory(:configuration)
    f.loaders = [ConfigurationDummyLoader]
    f
  end

  let(:configuration_file) do
    'configuration.txt'
  end

  after do
    ConfigurationDummyLoader.clear
  end
end

shared_context 'register_map common' do
  class RegisterMapDummyLoader < RGen::InputBase::Loader
    self.supported_types  = [:txt]

    def self.load_data(data = nil)
      @load_data  = data  if data
      @load_data
    end

    def self.clear
      @load_data  = nil
    end

    def load_file(file)
      create_map(self.class.load_data, file)
    end
  end

  def build_register_map_factory
    f         = RGen.generator.builder.build_factory(:register_map)
    f.loaders = [RegisterMapDummyLoader]
    f
  end

  def build_register_block_factory
    build_register_map_factory.instance_variable_get(:@child_factory)
  end

  def position(sheet_name, row, column)
    RGen::RegisterMap::GenericMap::Cell::Position.new(register_map_file, sheet_name, row, column)
  end

  let(:register_map_file) do
    'register_map.txt'
  end

  after do
    RegisterMapDummyLoader.clear
  end
end
