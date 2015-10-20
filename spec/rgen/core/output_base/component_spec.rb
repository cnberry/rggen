require_relative '../../../spec_helper'

module RGen::OutputBase
  describe Component do
    def create_component(parent = nil)
      component = Component.new
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
      @component        = create_component
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

    describe "#generate_code" do
      let(:buffer) do
        []
      end

      it "kindで指定した種類のコードを生成する" do
        component.generate_code(:foo, :top_down, buffer)
        expect(buffer).to match [
          "#{component.object_id}_foo",
          "#{child_components[0].object_id}_foo",
          "#{grandchild_components[0].object_id}_foo",
          "#{grandchild_components[1].object_id}_foo",
          "#{child_components[1].object_id}_foo",
          "#{grandchild_components[2].object_id}_foo",
          "#{grandchild_components[3].object_id}_foo"
        ]
      end

      context "modeが:top_downを指定した場合" do
        it "上位からコードの生成を行う" do
          component.generate_code(:foo, :top_down, buffer)
          expect(buffer).to match [
            "#{component.object_id}_foo",
            "#{child_components[0].object_id}_foo",
            "#{grandchild_components[0].object_id}_foo",
            "#{grandchild_components[1].object_id}_foo",
            "#{child_components[1].object_id}_foo",
            "#{grandchild_components[2].object_id}_foo",
            "#{grandchild_components[3].object_id}_foo"
          ]
        end
      end

      context "modeが:bottom_upを指定した場合" do
        it "下位からコードの生成を行う" do
          component.generate_code(:foo, :bottom_up, buffer)
          expect(buffer).to match [
            "#{grandchild_components[0].object_id}_foo",
            "#{grandchild_components[1].object_id}_foo",
            "#{child_components[0].object_id}_foo",
            "#{grandchild_components[2].object_id}_foo",
            "#{grandchild_components[3].object_id}_foo",
            "#{child_components[1].object_id}_foo",
            "#{component.object_id}_foo"
          ]
        end
      end
    end

    describe "#write_file" do
      before do
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

      context "出力ディレクトリが指定されていない場合" do
        let(:output_directory) do
          ''
        end

        it "空文字列を引数として、配下全アイテムオブジェクトの#write_fileを呼び出す" do
          component.write_file
        end
      end

      context "出力ディレクトリが指定された場合" do
        let(:output_directory) do
          '/foo/bar'
        end

        it "与えられた出力ディレクトリを引数として、配下全アイテムオブジェクトの#write_fileを呼び出す" do
          component.write_file(output_directory)
        end
      end
    end

    describe "#create_context" do
      let(:child_contexts) do
        child_components.map {|child_component| child_component.context}
      end

      let(:grandchild_contexts) do
        grandchild_components.map {|grandchild_component| grandchild_component.context}
      end

      it "自身及び配下のジェネレータでコンテキストオブジェクトを作成する" do
        component.create_context
        expect(component.context  ).to be_kind_of(Context)
        expect(child_contexts     ).to all(be_kind_of(Context))
        expect(grandchild_contexts).to all(be_kind_of(Context))
      end

      specify "生成されたコンテキストの#levelは属するジェネレータの#levelと同じ値を取る" do
        component.create_context
        expect(component.context.level         ).to eq component.level
        expect(     child_contexts.map(&:level)).to all(eq      child_components[0].level)
        expect(grandchild_contexts.map(&:level)).to all(eq grandchild_components[0].level)
      end
    end
  end
end
