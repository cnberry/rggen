require_relative '../../spec_helper'

module RGen::OutputBase
  describe CodeBlock do
    let(:code_block) do
      CodeBlock.new
    end

    describe "#<<" do
      context "単語を追加する場合" do
        before do
          code_block << 'foo'
          code_block << :bar << 1
        end

        it "最終行の末尾に文字列を追加する" do
          expect(code_block.to_s).to eq "foobar1"
        end
      end

      context "複数行の文字列を追加する場合" do
        before do
          code_block << 'foo'
          code_block << "bar\n  \n  baz  \nqux"
        end

        it "行ごとに追加する" do
          expect(code_block.to_s).to eq "foobar\n\n  baz\nqux"
        end
      end

      context ":newlineを追加する場合" do
        before do
          code_block << 'foo'
          code_block << :newline
          code_block << :bar
        end

        it "新しい行を追加する" do
          expect(code_block.to_s).to eq "foo\nbar"
        end
      end

      context "最終行が空ではないCodeBlockを追加する場合" do
        before do
          code_block << 'foo'
          code_block << added_code_block
          code_block << 'baz'
        end

        let(:added_code_block) do
          block = CodeBlock.new
          block << 'bar'
          block << :newline
          block << 'baz'
        end

        it "与えられたコードブロックを末尾に追加し、また、新しい行を追加する" do
          expect(code_block.to_s).to eq "foo\nbar\nbaz\nbaz"
        end
      end

      context "最終行が空のCodeBlockを追加する場合" do
        before do
          code_block << 'foo'
          code_block << added_code_block
          code_block << 'baz'
        end

        let(:added_code_block) do
          block         = CodeBlock.new
          block.indent  = 2
          block << 'bar'
          block << :newline
          block << 'baz' << :newline
        end

        it "与えられたコードブロックを末尾に追加し、最終行のインデントを追加先のインデントに合わせる" do
          expect(code_block.to_s).to eq "foo\n  bar\n  baz\nbaz"
        end
      end
    end

    describe "#indent=" do
      before do
        code_block << 'foo' << :newline
        code_block << 'bar'
        code_block.indent  += 2
        code_block << :newline
        code_block.indent  += 2
        code_block << "baz\n\nqux\n"
        code_block << added_code_block
        code_block << :newline
        code_block.indent  -= 4
        code_block << 'foobar'
      end

      let(:added_code_block) do
        block = CodeBlock.new
        block << 'quux' << :newline
        block.indent += 2
        block << 'corge'
      end

      it "末尾の行から与えられたインデント幅を設定する" do
        expect(code_block.to_s).to eq "foo\n  bar\n    baz\n\n    qux\n\n    quux\n      corge\n\nfoobar"
      end
    end

    describe "#to_s" do
      before do
        code_block << 'foo  ' << :newline
        code_block << '  '    << :newline
        code_block << "  bar\t  "
      end

      specify "行末の空白文字を取り除く" do
        expect(code_block.to_s).to eq "foo\n\n  bar"
      end
    end
  end
end
