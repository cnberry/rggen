require_relative '../spec_helper'

describe 'register_block/reg_model_creator' do
  include_context 'bit field type common'
  include_context 'configuration common'
  include_context 'ral common'

  before(:all) do
    enable :global, [:data_width, :address_width]
    enable :register_block, [:name, :byte_size]
    enable :register , [:name, :offset_address, :array, :shadow, :accessibility]
    enable :bit_field, [:name, :bit_assignment, :type, :initial_value, :reference]
    enable :bit_field, :type, [:rw, :ro, :wo]
    enable :register , :reg_model_creation
    enable :register_block, :reg_model_creator

    configuration = create_configuration
    register_map  = create_register_map(
      configuration,
      "block_0" => [
        [nil, nil, "block_0"                                                                                               ],
        [nil, nil, 256                                                                                                     ],
        [                                                                                                                  ],
        [                                                                                                                  ],
        [nil, "register_0", "0x00"     , nil     , nil                           , "bit_field_0_0", "[31:16]", "rw", 0, nil],
        [nil, nil         , nil        , nil     , nil                           , "bit_field_0_1", "[15: 0]", "rw", 0, nil],
        [nil, "register_1", "0x04-0x0B", "[2]"   , nil                           , "bit_field_1_0", "[31:16]", "ro", 0, nil],
        [nil, nil         , nil        , nil     , nil                           , "bit_field_1_1", "[15: 0]", "ro", 0, nil],
        [nil, "register_2", "0x0C"     , "[2]"   , "bit_field_0_0"               , "bit_field_2_0", "[31:16]", "wo", 0, nil],
        [nil, nil         , nil        , nil     , nil                           , "bit_field_2_1", "[15: 0]", "wo", 0, nil],
        [nil, "register_3", "0x10"     , "[2, 4]", "bit_field_0_0, bit_field_0_1", "bit_field_3_0", "[31:16]", "rw", 0, nil],
        [nil, nil         , nil        , nil     , nil                           , "bit_field_3_1", "[15: 0]", "rw", 0, nil]
      ]
    )
    @ral  = build_ral_factory.create(configuration, register_map).register_blocks[0]
  end

  after(:all) do
    clear_enabled_items
  end

  let(:ral) do
    @ral
  end

  describe "#generate_code" do
    let(:expected_code) do
      <<'CODE'
function void create_registers();
  `rgen_ral_create_reg_model(register_0, "register_0", '{}, 8'h00, "RW", 0)
  foreach (register_1[i]) begin
    `rgen_ral_create_reg_model(register_1[i], "register_1", '{i}, 8'h04 + 4 * i, "RO", 0)
  end
  foreach (register_2[i]) begin
    `rgen_ral_create_reg_model(register_2[i], "register_2", '{i}, 8'h0c, "WO", 1)
  end
  foreach (register_3[i, j]) begin
    `rgen_ral_create_reg_model(register_3[i][j], "register_3", '{i, j}, 8'h10, "RW", 1)
  end
endfunction
CODE
    end

    it "レジスタモデルを生成するcreate_registersの定義を生成する" do
      expect(ral).to generate_code(:block_model_item, :top_down, expected_code)
    end
  end
end
