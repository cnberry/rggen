require_relative '../spec_helper'

describe 'bit_field/type' do
  include_context 'bit field type common'
  include_context 'configuration common'
  include_context 'rtl common'
  include_context 'ral common'

  before(:all) do
    items = {}
    [:foo, :bar, :baz].each do |item_name|
      RGen.list_item(:bit_field, :type, item_name) do
        register_map {items[item_name] = self}
        rtl {}
        ral do
          build do
            @access = :rw if item_name == :bar
          end
        end
      end
    end

    RGen.enable(:global, [:data_width, :address_width])
    RGen.enable(:register_block, [:name, :byte_size])
    RGen.enable(:register, [:name, :offset_address, :array, :shadow])
    RGen.enable(:bit_field, [:name, :bit_assignment, :type, :reference])
    RGen.enable(:bit_field, :type, [:ro, :foo, :bar])

    @items    = items
    @factory  = build_register_map_factory
  end

  before(:all) do
    ConfigurationDummyLoader.load_data({})
    @configuration  = build_configuration_factory.create(configuration_file)
  end

  after(:all) do
    clear_enabled_items
    clear_dummy_list_items(:type, [:foo, :bar, :baz])
  end

  after do
    @items.each_value do |item|
      [:@readable, :@writable, :@required_width, :@use_reference, :@reference_options].each do |variable|
        if item.instance_variable_defined?(variable)
          item.remove_instance_variable(variable)
        end
      end
    end
  end

  let(:configuration) do
    @configuration
  end

  def define_item(item_name, &body)
    @items[item_name].class_eval(&body)
  end

  describe "register_map" do
    describe "#type" do
      let(:load_data) do
        [
          [nil, "register_0", "0x00", nil, nil, "bit_field_0_0", "[3]", "BAR", nil],
          [nil, nil         , nil   , nil, nil, "bit_field_0_1", "[2]", "foo", nil],
          [nil, nil         , nil   , nil, nil, "bit_field_0_2", "[1]", "fOo", nil],
          [nil, nil         , nil   , nil, nil, "bit_field_0_3", "[0]", "BaR", nil]
        ]
      end

      it "小文字化されたタイプ名を返す" do
        expect(bit_fields.map(&:type)).to match [:bar, :foo, :foo, :bar]
      end
    end

    describe ".read_write" do
      before do
        define_item(:foo) {read_write}
      end

      let(:load_data) do
        [[nil, "register_0", "0x00", nil, nil, "bit_field_0_0", "[0]", "foo", nil]]
      end

      it "アクセス属性をread-writeに設定する" do
        expect(bit_fields[0]).to match_access(:read_write)
      end
    end

    describe ".read_only" do
      before do
        define_item(:foo) {read_only}
      end

      let(:load_data) do
        [[nil, "register_0", "0x00", nil, nil, "bit_field_0_0", "[0]", "foo", nil]]
      end

      it "アクセス属性をread-onlyに設定する" do
        expect(bit_fields[0]).to match_access(:read_only)
      end
    end

    describe ".write_only" do
      before do
        define_item(:foo) {write_only}
      end

      let(:load_data) do
        [[nil, "register_0", "0x00", nil, nil, "bit_field_0_0", "[0]", "foo", nil]]
      end

      it "アクセス属性をwrite-onlyに設定する" do
        expect(bit_fields[0]).to match_access(:write_only)
      end
    end

    describe ".reserved" do
      before do
        define_item(:foo) {reserved}
      end

      let(:load_data) do
        [[nil, "register_0", "0x00", nil, nil, "bit_field_0_0", "[0]", "foo", nil]]
      end

      it "アクセス属性をreservedに設定する" do
        expect(bit_fields[0]).to match_access(:reserved)
      end
    end

    describe ".required_width" do
      context ".required_widthで必要なビット幅が設定されていない場合" do
        it "任意の幅のビットフィールドで使用できる" do
          set_load_data([
            [nil, "register_0", "0x00", nil, nil, "bit_field_0_0", "[15:8]", "foo", nil],
            [nil, nil         , nil   , nil, nil, "bit_field_0_1", "[0]"   , "foo", nil],
            [nil, "register_1", "0x04", nil, nil, "bit_field_1_0", "[31:0]", "foo", nil]
          ])
          expect {
            @factory.create(configuration, register_map_file)
          }.not_to raise_error
        end
      end

      context "必要なビット幅が値で設定されている場合" do
        before do
          define_item(:foo) {required_width 2}
        end

        it "設定したビット幅を持つビットフィールドで使用できる" do
          set_load_data([
            [nil, "register_0", "0x00", nil, nil, "bit_field_0_0", "[17:16]", "foo", nil],
            [nil, nil         , nil   , nil, nil, "bit_field_0_1", "[1:0]"  , "foo", nil]
          ])
          expect {
            @factory.create(configuration, register_map_file)
          }.not_to raise_error
        end

        context "設定した幅以外のビットフィールドで使用した場合" do
          it "RegisterMapErrorを発生させる" do
            {1 => "[0]", 3 => "[2:0]", 32 => "[31:0]"}.each do |width, assignment|
              set_load_data([[nil, "register_0", "0x00", nil, nil, "bit_field_0_0", assignment, "foo", nil]])
              expect {
                @factory.create(configuration, register_map_file)
              }.to raise_register_map_error("2 bit(s) width required: #{width} bit(s)", position("block_0", 4, 7))
            end
          end
        end
      end

      context "必要なビット幅が配列で複数指定されている場合" do
        before do
          define_item(:foo) {required_width [1, 3]}
        end

        it "指定した幅のどれかを持つビットフィールドで使用できる" do
          set_load_data([
            [nil, "register_0", "0x00", nil, nil, "bit_field0_0", "[6:4]", "foo", nil],
            [nil, nil         , nil   , nil, nil, "bit_field0_1", "[0]"  , "foo", nil]
          ])
          expect {
            @factory.create(configuration, register_map_file)
          }.not_to raise_error
        end

        context "指定された以外の幅を持つビットフィールドで使用した場合" do
          it "RGen::RegisterMapErrorを発生させる" do
            {2 => "[1:0]", 4 => "[3:0]"}.each do |width, assignment|
              set_load_data([[nil, "register_0", "0x00", nil, nil, "bit_field_0_0", assignment, "foo", nil]])
              expect {
                @factory.create(configuration, register_map_file)
              }.to raise_register_map_error("#{[1, 3]} bit(s) width required: #{width} bit(s)", position("block_0", 4, 7))
            end
          end
        end
      end

      context "必要なビット幅が範囲で指定されている場合" do
        before do
          define_item(:foo) {required_width 2..4}
        end

        it "指定した幅のどれかを持つビットフィールドで使用できる" do
          set_load_data([
            [nil, "register_0", "0x00", nil, nil, "bit_field0_0", "[11:8]", "foo", nil],
            [nil, nil         , nil   , nil, nil, "bit_field0_1", "[6:4]" , "foo", nil],
            [nil, nil         , nil   , nil, nil, "bit_field0_2", "[1:0]" , "foo", nil]
          ])
          expect {
            @factory.create(configuration, register_map_file)
          }.not_to raise_error
        end

        context "指定された以外の幅を持つビットフィールドで使用した場合" do
          it "RGen::RegisterMapErrorを発生させる" do
            {1 => "[0]", 5 => "[4:0]"}.each do |width, assignment|
              set_load_data([[nil, "register_0", "0x00", nil, nil, "bit_field_0_0", assignment, "foo", nil]])
              expect {
                @factory.create(configuration, register_map_file)
              }.to raise_register_map_error("#{2..4} bit(s) width required: #{width} bit(s)", position("block_0", 4, 7))
            end
          end
        end
      end

      context "必要なビット幅が:full_widthで設定されている場合" do
        before do
          define_item(:foo) {required_width full_width}
        end

        it "コンフィグレーションで指定したデータ幅を持つビットフィールドで使用できる" do
          set_load_data([
            [nil, "register_0", "0x00", nil, nil, "bit_field0_0", "[31:0]", "foo", nil]
          ])
          expect {
            @factory.create(configuration, register_map_file)
          }.not_to raise_error
        end

        context "データ幅以外のビットフィールド使用した場合" do
          it "RGen::RegisterMapErrorを発生させる" do
            {1 => "[0]", 31 => "[30:0]"}.each do |width, assignment|
              set_load_data([[nil, "register_0", "0x00", nil, nil, "bit_field_0_0", assignment, "foo", nil]])
              expect {
                @factory.create(configuration, register_map_file)
              }.to raise_register_map_error("#{configuration.data_width} bit(s) width required: #{width} bit(s)", position("block_0", 4, 7))
            end
          end
        end
      end
    end

    describe ".use_reference" do
      context ".use_referenceで参照信号設定がない場合" do
        it "参照ビットフィールドの指定に有無にかかわらず使用できる" do
          set_load_data([
            [nil, "register_0", "0x00", nil, nil, "bit_field_0_0", "[15:8]", "foo", nil            ],
            [nil, nil         , nil   , nil, nil, "bit_field_0_1", "[0]"   , "foo", nil            ],
            [nil, "register_1", "0x04", nil, nil, "bit_field_1_0", "[31:0]", "foo", "bit_field_0_0"]
          ])
          expect {
            @factory.create(configuration, register_map_file)
          }.not_to raise_error
        end
      end

      describe "requiredオプション" do
        context "オプションの指定がない場合" do
          before do
            define_item(:foo) {use_reference}
          end

          it "参照ビットフィールドの指定に有無にかかわらず使用できる" do
            set_load_data([
              [nil, "register_0", "0x00", nil, nil, "bit_field_0_0", "[1]", "foo", nil            ],
              [nil, nil         , nil   , nil, nil, "bit_field_0_1", "[0]", "foo", "bit_field_0_0"]
            ])
            expect {
              @factory.create(configuration, register_map_file)
            }.not_to raise_error
          end
        end

        context "falseに設定されている場合" do
          before do
            define_item(:foo) {use_reference required:false}
          end

          it "参照ビットフィールドの指定に有無にかかわらず使用できる" do
            set_load_data([
              [nil, "register_0", "0x00", nil, nil, "bit_field_0_0", "[2]"  , "foo", nil            ],
              [nil, nil         , nil   , nil, nil, "bit_field_0_1", "[1:0]", "foo", "bit_field_0_0"]
            ])
            expect {
              @factory.create(configuration, register_map_file)
            }.not_to raise_error
          end
        end

        context "trueに設定されている場合" do
          before do
            define_item(:foo) {use_reference required:true}
          end

          it "参照ビットフィールドを持つビットフィールドで使用できる" do
            set_load_data([
              [nil, "register_0", "0x00", nil, nil, "bit_field_0_0", "[4]"  , "bar", nil            ],
              [nil, nil         , nil   , nil, nil, "bit_field_0_1", "[3:0]", "foo", "bit_field_0_0"]
            ])
            expect {
              @factory.create(configuration, register_map_file)
            }.not_to raise_error
          end

          context "参照信号を持たないビットフィールで使用した場合" do
            it "RGen::RegisterMapErrorを発生させる" do
              set_load_data([
                [nil, "register_0", "0x00", nil, nil, "bit_field_0_0", "[7:4]", "foo", nil]
              ])
              expect {
                @factory.create(configuration, register_map_file)
              }.to raise_error "reference bit field required", position("block_0", 4, 7)
            end
          end
        end
      end

      describe "widthオプション" do
        context "参照ビットフィールド幅の指定がない場合" do
          before do
            define_item(:foo) {use_reference}
          end

          it "1ビットの参照ビットフィールドを持つビットフィールで使用できる" do
            set_load_data([
              [nil, "register_0", "0x00", nil, nil, "bit_field_0_0", "[1]", "bar", nil            ],
              [nil, nil         , nil   , nil, nil, "bit_field_0_1", "[0]", "foo", "bit_field_0_0"]
            ])
            expect {
              @factory.create(configuration, register_map_file)
            }.not_to raise_error
          end

          context "2ビット以上のビットフィールドを参照ビットフィールドに指定した場合" do
            it "RGen::RegisterMapErrorを発生させる" do
              set_load_data([
                [nil, "register_0", "0x00", nil, nil, "bit_field_0_0", "[2:1]", "bar", nil            ],
                [nil, nil         , nil   , nil, nil, "bit_field_0_1", "[0]"  , "foo", "bit_field_0_0"]
              ])
              expect {
                @factory.create(configuration, register_map_file)
              }.to raise_error "1 bit(s) reference bit field required: 2", position("block_0", 4, 7)
            end
          end
        end

        context "参照ビットフィールド幅が数字で指定された場合" do
          before do
            define_item(:foo) {use_reference width:2}
          end

          it "指定幅の参照ビットフィールドを持つビットフィールで使用できる" do
            set_load_data([
              [nil, "register_0", "0x00", nil, nil, "bit_field_0_0", "[5:4]", "bar", nil            ],
              [nil, nil         , nil   , nil, nil, "bit_field_0_1", "[3:0]", "foo", "bit_field_0_0"]
            ])
            expect {
              @factory.create(configuration, register_map_file)
            }.not_to raise_error
          end

          context "指定幅以外のビットフィールドを参照ビットフィールドに指定した場合" do
            it "RGen::RegisterMapErrorを発生させる" do
              {3 => "[6:4]", 1 => "[4]"}.each do |width, assigment|
                set_load_data([
                  [nil, "register_0", "0x00", nil, nil, "bit_field_0_0", assigment, "bar", nil            ],
                  [nil, nil         , nil   , nil, nil, "bit_field_0_1", "[0]"    , "foo", "bit_field_0_0"]
                ])
                expect {
                  @factory.create(configuration, register_map_file)
                }.to raise_error "2 bit(s) reference bit field required: #{width}", position("block_0", 4, 7)
              end
            end
          end
        end

        context "参照ビットフィールド幅が:same_widthで指定された場合" do
          before do
            define_item(:foo) {use_reference width:same_width}
          end

          it "同じ幅の参照ビットフィールドを持つビットフィールで使用できる" do
            set_load_data([
              [nil, "register_0", "0x00", nil, nil, "bit_field_0_0", "[7:4]", "bar", nil            ],
              [nil, nil         , nil   , nil, nil, "bit_field_0_1", "[3:0]", "foo", "bit_field_0_0"]
            ])
            expect {
              @factory.create(configuration, register_map_file)
            }.not_to raise_error
          end

          context "違う幅のビットフィールドを参照ビットフィールドに指定した場合" do
            it "RGen::RegisterMapErrorを発生させる" do
              {3 => "[6:4]", 1 => "[4]"}.each do |width, assigment|
                set_load_data([
                  [nil, "register_0", "0x00", nil, nil, "bit_field_0_0", assigment, "bar", nil            ],
                  [nil, nil         , nil   , nil, nil, "bit_field_0_1", "[1:0]"  , "foo", "bit_field_0_0"]
                ])
                expect {
                  @factory.create(configuration, register_map_file)
                }.to raise_error "2 bit(s) reference bit field required: #{width}", position("block_0", 4, 7)
              end
            end
          end
        end
      end
    end

    context "Rgen.enableで有効にされたタイプ以外が入力された場合" do
      it "RegisterMapErrorを発生させる" do
        ["baz", "qux"].each do |type|
          set_load_data([[nil, "register_0", "0x00", nil, nil, "bit_field_0_0", "[0]", type, nil]])
          expect {
            @factory.create(configuration, register_map_file)
          }.to raise_register_map_error("unknown bit field type: #{type}", position("block_0", 4, 7))
        end
      end
    end
  end

  describe "rtl" do
    let(:register_map) do
      set_load_data([
        [nil, "register_0", "0x00"     , nil     , nil                           , "bit_field_0_0", "[31:0]" , "foo", nil],
        [nil, "register_1", "0x04-0x0B", "[2]"   , nil                           , "bit_field_1_0", "[0]"    , "foo", nil],
        [nil, "register_2", "0x0C"     , "[3, 4]", "bit_field_3_0, bit_field_3_1", "bit_field_2_0", "[0]"    , "foo", nil],
        [nil, "register_3", "0x10"     , nil     , nil                           , "bit_field_3_0", "[31:16]", "ro" , nil],
        [nil, nil         , nil        , nil     , nil                           , "bit_field_3_1", "[15:0]" , "ro" , nil]
      ])
      @factory.create(configuration, register_map_file)
    end

    let(:rtl) do
      build_rtl_factory.create(@configuration, register_map).bit_fields
    end

    context "アクセス属性がread-writeの場合" do
      before do
        define_item(:foo) {read_write}
      end

      it "value信号を持つ" do
        expect(rtl[0]).to have_logic(:value, name: 'bit_field_0_0_value', width: 32)
        expect(rtl[1]).to have_logic(:value, name: 'bit_field_1_0_value', width: 1, dimensions: [2])
        expect(rtl[2]).to have_logic(:value, name: 'bit_field_2_0_value', width: 1, dimensions: [3, 4])
      end
    end

    context "アクセス属性がread-onlyの場合" do
      before do
        define_item(:foo) {read_only}
      end

      it "value信号を持つ" do
        expect(rtl[0]).to have_logic(:value, name: 'bit_field_0_0_value', width: 32)
        expect(rtl[1]).to have_logic(:value, name: 'bit_field_1_0_value', width: 1, dimensions: [2])
        expect(rtl[2]).to have_logic(:value, name: 'bit_field_2_0_value', width: 1, dimensions: [3, 4])
      end
    end

    context "アクセス属性がwrite-onlyの場合" do
      before do
        define_item(:foo) {write_only}
      end

      it "value信号を持つ" do
        expect(rtl[0]).to have_logic(:value, name: 'bit_field_0_0_value', width: 32)
        expect(rtl[1]).to have_logic(:value, name: 'bit_field_1_0_value', width: 1, dimensions: [2])
        expect(rtl[2]).to have_logic(:value, name: 'bit_field_2_0_value', width: 1, dimensions: [3, 4])
      end
    end

    context "アクセス属性がreservedの場合" do
      before do
        define_item(:foo) {reserved}
      end

      it "value信号を持たない" do
        expect(rtl[0]).not_to have_identifier(:value, name: 'bit_field_0_0_value')
        expect(rtl[0]).not_to have_signal_declaration(name: 'bit_field_0_0_value', data_type: :logic, width: 32)
        expect(rtl[1]).not_to have_identifier(:value, name: 'bit_field_1_0_value')
        expect(rtl[1]).not_to have_signal_declaration(name: 'bit_field_1_0_value', data_type: :logic, width: 1, dimensions: [2])
        expect(rtl[2]).not_to have_identifier(:value, name: 'bit_field_2_0_value')
        expect(rtl[2]).not_to have_signal_declaration(name: 'bit_field_2_0_value', data_type: :logic, width: 1, dimensions: [3, 4])
      end
    end
  end

  describe "ral" do
    let(:register_map) do
      set_load_data([
        [nil, "register_0", "0x00", nil, nil, "bit_field_0_0", "[31:0]", "ro" , nil],
        [nil, "register_1", "0x04", nil, nil, "bit_field_1_0", "[31:0]", "foo", nil],
        [nil, "register_2", "0x08", nil, nil, "bit_field_2_0", "[31:0]", "bar", nil]
      ])
      @factory.create(configuration, register_map_file)
    end

    let(:ral) do
      build_ral_factory.create(@configuration, register_map).bit_fields
    end

    describe "#access" do
      context "@accessが設定されていない場合" do
        it "大文字化したタイプ名を返す" do
          expect(ral[0].access).to eq '"RO"'
          expect(ral[1].access).to eq '"FOO"'
        end
      end

      context "@accessが設定されてる場合" do
        it "大文字化した@accessを返す" do
          expect(ral[2].access).to eq '"RW"'
        end
      end
    end
  end
end
