#!/usr/bin/env rvm-ruby 1.9.3
# -*- encoding: us-ascii -*-

describe "decode" do
  context "with baked file" do
    before :all do
      exec("rm -f output/test_actual/decode_baked")
      exec("rm -f output/test_actual/decode_baked_stderr")
      exec("rm -rf data/test/archive/mixed_formats")
      exec("cp -r data/test/archive/mixed_formats_init data/test/archive/mixed_formats")
      exec("bun decode data/test/archive/mixed_formats/fass/1986/script/script.f_19860213/1-1/tape.ar120.0740_19860213_134229.txt \
                2>output/test_actual/decode_baked_stderr \
                >output/test_actual/decode_baked", allowed: [1])
    end
    it "should fail" do
      $?.exitstatus.should == 1
    end
    it "should not write output" do
      "decode_baked".should be_an_empty_file
    end
    it "should write the expected message on STDERR" do
      "decode_baked_stderr".should match_expected_output
    end
    after :all do
      backtrace
      exec_on_success("rm -f output/test_actual/decode_baked")
      exec_on_success("rm -f output/test_actual/decode_baked_stderr")
      exec_on_success("rm -rf data/test/archive/mixed_formats")
    end
  end
 context "with baked file and --quiet" do
    before :all do
      exec("rm -f output/test_actual/decode_baked")
      exec("rm -f output/test_actual/decode_baked_stderr")
      exec("bun decode --quiet data/test/archive/mixed_formats/fass/1986/script/script.f_19860213/1-1/tape.ar120.0740_19860213_134229.txt \
                2>output/test_actual/decode_baked_stderr \
                >output/test_actual/decode_baked", allowed: [1])
    end
    it "should fail" do
      $?.exitstatus.should == 1
    end
    it "should not write output" do
      "decode_baked".should be_an_empty_file
    end
    it "should write nothing on STDERR" do
      "decode_baked_stderr".should be_an_empty_file
    end
    after :all do
      backtrace
      exec_on_success("rm -f output/test_actual/decode_baked")
      exec_on_success("rm -f output/test_actual/decode_baked_stderr")
    end
  end
  context "with text file" do
    context "without expand option" do
      before :all do
        exec("rm -f output/test_actual/decode_ar003.0698")
        exec("bun decode #{TEST_ARCHIVE}/ar003.0698.bun \
                  >output/test_actual/decode_ar003.0698")
      end
      it "should match the expected output" do
        "decode_ar003.0698".should match_expected_output_except_for(DECODE_PATTERNS)
      end
      after :all do
        backtrace
        exec_on_success("rm -f output/test_actual/decode_ar003.0698")
      end
    end
    context "with expand option" do
      before :all do
        exec("rm -f output/test_actual/decode_ar003.0698")
        exec("bun decode --expand #{TEST_ARCHIVE}/ar003.0698.bun \
                  >output/test_actual/decode_ar003.0698")
      end
      it "should match the expected output" do
        "decode_ar003.0698".should match_expected_output_except_for(DECODE_PATTERNS)
      end
      after :all do
        backtrace
        exec_on_success("rm -f output/test_actual/decode_ar003.0698")
      end
    end
    context "from STDIN" do
      before :all do
        exec("rm -f output/test_actual/decode_ar003.0698")
        exec("cat #{TEST_ARCHIVE}/ar003.0698.bun | bun decode - \
                  >output/test_actual/decode_ar003.0698")
      end
      it "should match the expected output" do
        "decode_ar003.0698".should match_expected_output_except_for(DECODE_PATTERNS)
      end
      after :all do
        backtrace
        exec_on_success("rm -f output/test_actual/decode_ar003.0698")
      end
    end
    context "with existing file" do
      before :all do
        exec("rm -f output/test_actual/decode_ar003.0698")
        exec("rm -f output/test_actual/decode_ar003.0698_existing_stderr.txt")
        exec("echo foo >output/test_actual/decode_ar003.0698")
        exec("bun decode #{TEST_ARCHIVE}/ar003.0698.bun \
                  output/test_actual/decode_ar003.0698 \
                  2>output/test_actual/decode_ar003.0698_existing_stderr.txt", allowed: [1])
      end
      it "should fail" do
        $?.exitstatus.should == 1
      end
      it "should not overwrite the existing file" do
        "output/test_actual/decode_ar003.0698".should contain_content('foo')
      end
      it "should write appropriate messages on STDERR" do
        "decode_ar003.0698_existing_stderr.txt".should match_expected_output
      end
      after :all do
        backtrace
        exec_on_success("rm -f output/test_actual/decode_ar003.0698")
        exec_on_success("rm -f output/test_actual/decode_ar003.0698_existing_stderr.txt")
      end
    end
    context "with existing file and --quiet" do
      before :all do
        exec("rm -f output/test_actual/decode_ar003.0698")
        exec("rm -f output/test_actual/decode_ar003.0698_existing_stderr.txt")
        exec("echo foo >output/test_actual/decode_ar003.0698")
        exec("bun decode --quiet #{TEST_ARCHIVE}/ar003.0698.bun \
                  output/test_actual/decode_ar003.0698 \
                  2>output/test_actual/decode_ar003.0698_existing_stderr.txt", allowed: [1])
      end
      it "should fail" do
        $?.exitstatus.should == 1
      end
      it "should not overwrite the existing file" do
        "output/test_actual/decode_ar003.0698".should contain_content('foo')
      end
      it "should write nothing on STDERR" do
        "output/test_actual/decode_ar003.0698_existing_stderr.txt".should be_an_empty_file
      end
      after :all do
        backtrace
        exec_on_success("rm -f output/test_actual/decode_ar003.0698")
        exec_on_success("rm -f output/test_actual/decode_ar003.0698_existing_stderr.txt")
      end
    end
    context "with existing file and --force" do
      before :all do
        exec("rm -f output/test_actual/decode_ar003.0698")
        exec("echo foo >output/test_actual/decode_ar003.0698")
        exec("bun decode --force #{TEST_ARCHIVE}/ar003.0698.bun \
                  output/test_actual/decode_ar003.0698")
      end
      it "should match the expected output" do
        "decode_ar003.0698".should match_expected_output_except_for(DECODE_PATTERNS)
      end
      after :all do
        backtrace
        exec_on_success("rm -f output/test_actual/decode_ar003.0698")
      end
    end
  end
  context "with huffman file" do
    before :all do
      exec("rm -f output/test_actual/decode_ar003.0701")
      exec("bun decode #{TEST_ARCHIVE}/ar003.0701.bun \
                >output/test_actual/decode_ar003.0701")
    end
    it "should match the expected output" do
      "decode_ar003.0701".should match_expected_output_except_for(DECODE_PATTERNS)
    end
    after :all do
      backtrace
      exec_on_success("rm -f output/test_actual/decode_ar003.0701")
    end
  end
  context "with frozen file" do
    context "and +0 shard argument" do
      before :all do
        exec("rm -rf output/test_actual/decode_ar004.0888_0")
        exec("bun decode -S +0 #{TEST_ARCHIVE}/ar004.0888.bun \
                  >output/test_actual/decode_ar004.0888_0")
      end
      it "should match the expected output" do
        "decode_ar004.0888_0".should match_expected_output_except_for(DECODE_PATTERNS)
      end
      after :all do
        backtrace
        exec_on_success("rm -rf output/test_actual/decode_ar004.0888_0")
      end
    end
    context "and [+0] shard syntax" do
      before :all do
        exec("rm -rf output/test_actual/decode_ar004.0888_0")
        exec("bun decode #{TEST_ARCHIVE}/ar004.0888.bun[+0] \
                  >output/test_actual/decode_ar004.0888_0")
      end
      it "should match the expected output" do
        "decode_ar004.0888_0".should match_expected_output_except_for(DECODE_PATTERNS)
      end
      after :all do
        backtrace
        exec_on_success("rm -rf output/test_actual/decode_ar004.0888_0")
      end
    end
    context "and [name] shard syntax" do
      before :all do
        exec("rm -rf output/test_actual/decode_ar004.0888_0")
        exec("bun decode #{TEST_ARCHIVE}/ar004.0888.bun[fasshole] \
                  >output/test_actual/decode_ar004.0888_0")
      end
      it "should match the expected output" do
        "decode_ar004.0888_0".should match_expected_output_except_for(DECODE_PATTERNS)
      end
      after :all do
        backtrace
        exec_on_success("rm -rf output/test_actual/decode_ar004.0888_0")
      end
    end
    context "and [name] shard syntax with --scrub" do
      before :all do
        exec("rm -rf output/test_actual/decode_ar074.1174_1.3b_scrub")
        exec("bun decode --scrub data/test/ar074.1174.bun[1.3b] \
                  >output/test_actual/decode_ar074.1174_1.3b_scrub")
      end
      it "should match the expected output" do
        "decode_ar074.1174_1.3b_scrub".should match_expected_output_except_for(DECODE_PATTERNS)
      end
      after :all do
        backtrace
        exec_on_success("rm -rf output/test_actual/decode_ar074.1174_1.3b_scrub")
      end
    end
    context "and no shard argument" do
      context "and no expand option" do
        before :all do
          exec("rm -rf output/test_actual/decode_ar004.0888")
          exec("bun decode #{TEST_ARCHIVE}/ar004.0888.bun \
                    2>/dev/null >output/test_actual/decode_ar004.0888", :allowed=>[1])
        end
        it "should fail" do
          $?.exitstatus.should == 1
        end
        after :all do
          backtrace
          exec_on_success("rm -rf output/test_actual/decode_ar004.0888")
        end
      end
      context "and expand option" do
        context "without output file name" do
          before :all do
            exec("rm -rf output/test_actual/decode_ar004.0888")
            exec("bun decode --expand #{TEST_ARCHIVE}/ar004.0888.bun \
                      2>/dev/null >output/test_actual/decode_ar004.0888", :allowed=>[1])
          end
          it "should fail" do
            $?.exitstatus.should == 1
          end
          after :all do
            backtrace
            exec_on_success("rm -rf output/test_actual/decode_ar004.0888")
          end
        end
        context "with '-' as output file name" do
          before :all do
            exec("rm -rf output/test_actual/decode_ar004.0888")
            exec("bun decode --expand #{TEST_ARCHIVE}/ar004.0888.bun - \
                      2>/dev/null >output/test_actual/decode_ar004.0888", :allowed=>[1])
          end
          it "should fail" do
            $?.exitstatus.should == 1
          end
          after :all do
            backtrace
            exec_on_success("rm -rf output/test_actual/decode_ar004.0888")
          end
        end
        context "with output file name" do
          before :all do
            exec("rm -rf output/test_actual/decode_ar004.0888")
            exec("rm -rf output/test_actual/decode_ar004.0888.ls.txt")
            exec("rm -rf output/test_actual/decode_ar004.0888_cat_3eleven.txt")
            exec("bun decode --expand #{TEST_ARCHIVE}/ar004.0888.bun \
                      output/test_actual/decode_ar004.0888")
          end
          it "should create a directory" do
            system('[ -d output/test_actual/decode_ar004.0888 ]').should be_true
          end
          it "should contain all the shards" do
            exec("ls output/test_actual/decode_ar004.0888 >output/test_actual/decode_ar004.0888.ls.txt")
            "decode_ar004.0888.ls.txt".should match_expected_output
          end
          it "should match the expected output in the shards" do
            exec("cat output/test_actual/decode_ar004.0888/3eleven >output/test_actual/decode_ar004.0888_cat_3eleven.txt")
            "decode_ar004.0888_cat_3eleven.txt".should match_expected_output_except_for(DECODE_PATTERNS)
          end
          after :all do
            backtrace
            exec_on_success("rm -rf output/test_actual/decode_ar004.0888")
            exec_on_success("rm -rf output/test_actual/decode_ar004.0888.ls.txt")
            exec_on_success("rm -f output/test_actual/decode_ar004.0888_cat_3eleven.txt")
            exec_on_success("rm -rf output/test_actual/decode_ar004.0888")
          end
        end
      end
    end
  end
end
