require_relative '../../spec_helper'

describe "yaml_loader" do
  include_context 'configuration common'

  before(:all) do
    RGen.enable(:global, [:address_width, :data_width])
    @factory  = RGen.generator.builder.build_factory(:configuration)
  end

  after(:all) do
    clear_enabled_items
  end

  let(:configuraiton) do
    @factory.create(yaml_file)
  end

  it "拡張子がymlのYAMLフォーマットのファイルをロードする" do
    c = @factory.create(File.join(__dir__, "files", "sample.yml"))
    expect(c). match_address_width(16)
    epxect(c). match_data_width(64)
  end

  it "拡張子がyamlのYAMLフォーマットのファイルをロードする" do
    c = @factory.create(File.join(__dir__, "files", "sample.yaml"))
    expect(c). match_address_width(64)
    epxect(c). match_data_width(16)
  end
end
