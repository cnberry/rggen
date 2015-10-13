require_relative 'spec_helper'

describe 'xlsx_loader' do
  before(:all) do
    RGen.enable(:register_block, :name)
    RGen.enable(:register      , :name)
    RGen.enable(:bit_field     , :name)
    @factory  = RGen.builder.build_factory(:register_map)
  end

  after(:all) do
    clear_enabled_items
  end

  let(:xlsx_file) do
    File.join(__dir__, 'files', 'sample.xlsx')
  end

  let(:ods_file) do
    File.join(__dir__, 'files', 'sample.ods')
  end

  let(:configuration) do
    RGen::InputBase::Component.new
  end

  shared_examples_for "loader" do |file_format|
    let(:register_map) do
      @factory.create(configuration, file)
    end

    let(:register_blocks) do
      register_map.register_blocks
    end

    let(:registers) do
      register_map.registers
    end

    let(:bit_fields) do
      register_map.bit_fields
    end

    it "#{file_format}フォーマットのファイルをロードする" do
      expect(register_blocks).to match([
        have_item(file, 'sheet_0', 0, 2, name: 'block_0'),
        have_item(file, 'sheet_2', 0, 2, name: 'block_2')
      ])
      expect(registers).to match([
        have_item(file, 'sheet_0', 3, 1, name: 'register_0'),
        have_item(file, 'sheet_0', 5, 1, name: 'register_1'),
        have_item(file, 'sheet_2', 3, 1, name: 'register_0'),
        have_item(file, 'sheet_2', 4, 1, name: 'register_1')
      ])
      expect(bit_fields).to match([
        have_item(file, 'sheet_0', 3, 2, name: 'bit_field_0_0'),
        have_item(file, 'sheet_0', 4, 2, name: 'bit_field_0_1'),
        have_item(file, 'sheet_0', 5, 2, name: 'bit_field_1_0'),
        have_item(file, 'sheet_2', 3, 2, name: 'bit_field_0_0'),
        have_item(file, 'sheet_2', 4, 2, name: 'bit_field_1_0'),
        have_item(file, 'sheet_2', 5, 2, name: 'bit_field_1_1')
      ])
    end
  end

  context "入力ファイルの拡張子がxlsxのとき" do
    it_should_behave_like 'loader', 'Excel(2007以降)' do
      let(:file) do
        xlsx_file
      end
    end
  end

  context "入力ファイルの拡張子がodsのとき" do
    it_should_behave_like 'loader', 'OpenOffice Spreadsheet' do
      let(:file) do
        ods_file
      end
    end
  end
end
