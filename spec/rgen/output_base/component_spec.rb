require_relative '../../spec_helper'

module RGen::OutputBase
  describe Component do
    def create_component(parent)
      component = Component.new(parent, configuration, register_map)
      [:foo, :bar].each do |kind|
        item  = Class.new(Item) {
          generate_code kind do |buffer|
            buffer  << "#{component.object_id}_#{kind}"
          end
        }.new(component)
        component.add_item(item)
      end
      parent.add_child(component) unless parent.nil?
      component
    end

    before do
      @component        = create_component(nil)
      @child_components = 2.times.map do
        create_component(@component)
      end
      @grandchild_components  = 4.times.map do |i|
        create_component(@child_components[i / 2])
      end
    end

    let(:component) do
      @component
    end

    let(:child_components) do
      @child_components
    end

    let(:grandchild_components) do
      @grandchild_components
    end

    let(:configuration) do
      RGen::InputBase::Component.new(nil)
    end

    let(:register_map) do
      r = RGen::InputBase::Component.new(nil)
      allow(r).to receive(:fields).and_return [:foo, :bar]
      r
    end

    it "階層アクセッサを持つ" do
      expect(component.hierarchy                   ).to     eq :register_map
      expect(child_components.map(&:hierarchy)     ).to all(eq :register_block)
      expect(grandchild_components.map(&:hierarchy)).to all(eq :register      )
    end

    specify "自身をレシーバとして、与えられたレジスタマップオブジェクトの各フィールドにアクセスできる" do
      expect(register_map).to receive(:foo)
      expect(register_map).to receive(:bar)
      component.foo
      component.bar
    end

    describe "#configuration" do
      it "与えられたコンフィグレーションオブジェクトを返す" do
        expect(component.configuration).to eql configuration
      end
    end

    describe "#build" do
      before do
        component.items.each do |item|
          expect(item).to receive(:build)
        end
        child_components.each do |child_component|
          child_component.items.each do |item|
            expect(item).to receive(:build)
          end
        end
        grandchild_components.each do |grandchild_component|
          grandchild_component.items.each do |item|
            expect(item).to receive(:build)
          end
        end
      end

      it "配下の全アイテムの#buildを呼び出す" do
        component.build
      end
    end

    describe "#generate_code" do
      let(:buffer) do
        CodeBlock.new
      end

      it "kindで指定した種類のコードを生成する" do
        component.generate_code(:foo, :top_down, buffer)
        expect(buffer.to_s).to eq [
          "#{component.object_id}_foo",
          "#{child_components[0].object_id}_foo",
          "#{grandchild_components[0].object_id}_foo",
          "#{grandchild_components[1].object_id}_foo",
          "#{child_components[1].object_id}_foo",
          "#{grandchild_components[2].object_id}_foo",
          "#{grandchild_components[3].object_id}_foo"
        ].join
      end

      context "modeが:top_downを指定した場合" do
        it "上位からコードの生成を行う" do
          component.generate_code(:foo, :top_down, buffer)
          expect(buffer.to_s).to eq [
            "#{component.object_id}_foo",
            "#{child_components[0].object_id}_foo",
            "#{grandchild_components[0].object_id}_foo",
            "#{grandchild_components[1].object_id}_foo",
            "#{child_components[1].object_id}_foo",
            "#{grandchild_components[2].object_id}_foo",
            "#{grandchild_components[3].object_id}_foo"
          ].join
        end
      end

      context "modeが:bottom_upを指定した場合" do
        it "下位からコードの生成を行う" do
          component.generate_code(:foo, :bottom_up, buffer)
          expect(buffer.to_s).to eq [
            "#{grandchild_components[0].object_id}_foo",
            "#{grandchild_components[1].object_id}_foo",
            "#{child_components[0].object_id}_foo",
            "#{grandchild_components[2].object_id}_foo",
            "#{grandchild_components[3].object_id}_foo",
            "#{child_components[1].object_id}_foo",
            "#{component.object_id}_foo"
          ].join
        end
      end

      context "バッファ用の配列を与えなかった場合" do
        let(:expected_code) do
          [
            "#{component.object_id}_foo",
            "#{child_components[0].object_id}_foo",
            "#{grandchild_components[0].object_id}_foo",
            "#{grandchild_components[1].object_id}_foo",
            "#{child_components[1].object_id}_foo",
            "#{grandchild_components[2].object_id}_foo",
            "#{grandchild_components[3].object_id}_foo"
          ].join
        end

        it "生成したコードを文字列として返す" do
          expect(component.generate_code(:foo, :top_down)).to eq expected_code
        end
      end
    end

    describe "#write_file" do
      before do
        component.output_directory  = 'baz'
        component.items.each do |item|
          expect(item).to receive(:write_file).with(output_directory)
        end
        child_components.map(&:items).flatten.each do |item|
          expect(item).to receive(:write_file).with(output_directory)
        end
        grandchild_components.map(&:items).flatten.each do |item|
          expect(item).to receive(:write_file).with(output_directory)
        end
      end

      let(:root_directory) do
        '/foo/bar'
      end

      let(:output_directory) do
        '/foo/bar/baz'
      end

      it "与えられた出力ディレクトリ/@output_directoryを引数として、配下全アイテムオブジェクトの#write_fileを呼び出す" do
        component.write_file(root_directory)
      end

      context "指定したディレクトリが存在しない場合" do
        before do
          expect(FileUtils).to receive(:mkpath).with(output_directory)
        end

        it "ディレクトリの作成する" do
          component.write_file(root_directory)
        end
      end
    end
  end
end
