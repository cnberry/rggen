require_relative '../spec_helper'

describe 'bit_fields/type/rw' do
  include_context 'bit field type common'
  include_context 'configuration common'
  include_context 'rtl common'

  before(:all) do
    RGen.enable(:global, [:data_width, :address_width])
    RGen.enable(:register_block, [:name, :byte_size])
    RGen.enable(:register_block, [:clock_reset, :host_if, :response_mux])
    RGen.enable(:register_block, :host_if, :apb)
    RGen.enable(:register, :name)
    RGen.enable(:bit_field, [:name, :bit_assignment, :type, :initial_value, :reference])
    RGen.enable(:bit_field, :type, :rw)

    @factory  = build_register_map_factory
  end

  before(:all) do
    ConfigurationDummyLoader.load_data({})
    @configuration  = build_configuration_factory.create(configuration_file)
  end

  after(:all) do
    clear_enabled_items
  end

  let(:configuration) do
    @configuration
  end

  describe "register_map" do
    describe "#type" do
      it ":rwを返す" do
        bit_fields  = build_bit_fields([
          [nil, "register_0", "bit_field_0_0", "[0]", "rw", '0', nil]
        ])
        expect(bit_fields[0].type).to be :rw
      end
    end

    it "アクセス属性はread-write" do
      bit_fields  = build_bit_fields([
        [nil, "register_0", "bit_field_0_0", "[0]", "rw", '0', nil]
      ])
      expect(bit_fields[0]).to match_access(:read_write)
    end

    it "任意のビット幅を持つビットフィールドで使用できる" do
      expect {
        build_bit_fields([
          [nil, "register_0", "bit_field_0_0", "[0]"   , "rw", '0', nil],
          [nil, "register_1", "bit_field_1_0", "[1:0]" , "rw", '0', nil],
          [nil, "register_2", "bit_field_2_0", "[3:0]" , "rw", '0', nil],
          [nil, "register_3", "bit_field_3_0", "[7:0]" , "rw", '0', nil],
          [nil, "register_4", "bit_field_4_0", "[15:0]", "rw", '0', nil],
          [nil, "register_5", "bit_field_5_0", "[31:0]", "rw", '0', nil]
        ])
      }.not_to raise_error
    end

    it "参照ビットフィールドの指定に有無にかかわらず使用できる" do
      expect {
        build_bit_fields([
          [nil, "register_0", "bit_field_0_0", "[0]"   , "rw", '0', nil            ],
          [nil, "register_1", "bit_field_1_0", "[1:0]" , "rw", '0', "bit_field_0_0"]
        ])
      }.not_to raise_error
    end
  end

  describe "#rtl" do
    before(:all) do
      register_map  = create_register_map(
        @configuration,
        "block_0" => [
          [nil, nil, "block_0"                                               ],
          [nil, nil, 256                                                     ],
          [nil, nil, nil                                                     ],
          [nil, nil, nil                                                     ],
          [nil, 'register_0', 'bit_field_0_0', "[31:16]", "rw", '0xabcd', nil],
          [nil, nil         , 'bit_field_0_1', "[0]"    , "rw", '1'     , nil],
          [nil, 'register_1', 'bit_field_1_0', "[31:0]" , "rw", '0'     , nil]
        ]
      )
      @rtl  = build_rtl_factory.create(@configuration, register_map).bit_fields
    end

    let(:rtl) do
      @rtl
    end

    it "出力ポートvalue_outを持つ" do
      expect(rtl[0]).to have_output(:value_out, name: 'o_bit_field_0_0', width: 16)
      expect(rtl[1]).to have_output(:value_out, name: 'o_bit_field_0_1', width: 1 )
      expect(rtl[2]).to have_output(:value_out, name: 'o_bit_field_1_0', width: 32)
    end

    describe "#generate_code" do
      let(:expected_code_0) do
        <<'CODE'
assign o_bit_field_0_0 = bit_field_0_0_value;
rgen_bit_field_rw #(
  .WIDTH          (16),
  .INITIAL_VALUE  (16'habcd)
) u_bit_field_0_0 (
  .clk          (clk),
  .rst_n        (rst_n),
  .i_select     (register_select[0]),
  .i_write      (write),
  .i_write_data (write_data[31:16]),
  .i_write_mask (write_mask[31:16]),
  .o_value      (bit_field_0_0_value)
);
CODE
      end

      let(:expected_code_1) do
        <<'CODE'
assign o_bit_field_0_1 = bit_field_0_1_value;
rgen_bit_field_rw #(
  .WIDTH          (1),
  .INITIAL_VALUE  (1'h1)
) u_bit_field_0_1 (
  .clk          (clk),
  .rst_n        (rst_n),
  .i_select     (register_select[0]),
  .i_write      (write),
  .i_write_data (write_data[0]),
  .i_write_mask (write_mask[0]),
  .o_value      (bit_field_0_1_value)
);
CODE
      end

      let(:expected_code_2) do
        <<'CODE'
assign o_bit_field_1_0 = bit_field_1_0_value;
rgen_bit_field_rw #(
  .WIDTH          (32),
  .INITIAL_VALUE  (32'h00000000)
) u_bit_field_1_0 (
  .clk          (clk),
  .rst_n        (rst_n),
  .i_select     (register_select[1]),
  .i_write      (write),
  .i_write_data (write_data[31:0]),
  .i_write_mask (write_mask[31:0]),
  .o_value      (bit_field_1_0_value)
);
CODE
      end

      it "#value_outと#valueを接続、RWビットフィールドモジュールをインスタンスするコードを生成する" do
        expect(rtl[0]).to generate_code(:module_item, :top_down, expected_code_0)
        expect(rtl[1]).to generate_code(:module_item, :top_down, expected_code_1)
        expect(rtl[2]).to generate_code(:module_item, :top_down, expected_code_2)
      end
    end
  end
end
