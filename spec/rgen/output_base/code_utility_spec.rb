require_relative '../../spec_helper'

module RGen::OutputBase
  describe CodeUtility do
    before(:all) do
      @test_object  = Class.new {
        include CodeUtility
      }.new
    end

    let(:test_object) do
      @test_object
    end

    describe "#space" do
      context "引数ないとき" do
        it "空白を1つ返す" do
          expect(test_object.send(:space)).to eq ' '
        end
      end

      context "正数が与えられた場合" do
        it "与えた幅分の空白を返す" do
          expect(test_object.send(:space, 3)).to eq '   '
        end
      end
    end

    describe "#indent" do
      let(:expected_code) do
        <<'CODE'
  foo
    bar


  bar
  baz
CODE
      end

      it "ブロック内で入力されたコードに、sizeで指定されたインデントされたCodeBlockオブジェクトとして返す" do
        output  = test_object.send(:indent, 2) do |buf|
          buf << :foo       << :newline
          buf << '  bar'    << :newline
          buf               << :newline
          buf << "  \t"     << :newline
          buf << "bar\nbaz" << :newline
        end
        expect(output).to be_a_kind_of(CodeBlock)
        expect(output.to_s).to eq expected_code
      end
    end

    describe "#loop_index" do
      it "ネストの深さに応じたループ変数名を返す" do
        expect(test_object.send(:loop_index, 0)).to eq "i"
        expect(test_object.send(:loop_index, 1)).to eq "j"
        expect(test_object.send(:loop_index, 2)).to eq "k"
        expect(test_object.send(:loop_index, 3)).to eq "l"
      end
    end
  end
end
