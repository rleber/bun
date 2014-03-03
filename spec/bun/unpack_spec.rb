#!/usr/bin/env rvm-ruby 1.9.3
# -*- encoding: us-ascii -*-

describe "unpack" do
  context "to a file that already exists" do
    before :all do
      exec("rm -f output/test_actual/unpack_ar003.0698")
      exec("rm -f output/test_actual/unpack_ar003.0698_stderr")
      exec("echo foo > output/test_actual/unpack_ar003.0698")
      exec("rm -rf data/test/archive/general_test_packed")
      exec("cp -r data/test/archive/general_test_packed_init data/test/archive/general_test_packed")
      exec("bun unpack data/test/archive/general_test_packed/ar003.0698 output/test_actual/unpack_ar003.0698 \
            2>output/test_actual/unpack_ar003.0698_stderr", 
            allowed: [1])
    end
    it "should fail" do
      $?.exitstatus.should == 1
    end
    it "should match the expected output on STDERR" do
      "unpack_ar003.0698_stderr".should match_expected_output
    end
    it "should not overwrite the file" do
      "output/test_actual/unpack_ar003.0698".should contain_content("foo")
    end
    after :all do
      backtrace
      exec_on_success("rm -f output/test_actual/unpack_ar003.0698")
      exec_on_success("rm -f output/test_actual/unpack_ar003.0698_stderr")
      exec_on_success("rm -rf data/test/archive/general_test_packed")
    end
  end
  context "to a file that already exists with --quiet" do
    before :all do
      exec("rm -f output/test_actual/unpack_ar003.0698")
      exec("rm -f output/test_actual/unpack_ar003.0698_stderr")
      exec("echo foo > output/test_actual/unpack_ar003.0698")
      exec("rm -rf data/test/archive/general_test_packed")
      exec("cp -r data/test/archive/general_test_packed_init data/test/archive/general_test_packed")
      exec("bun unpack --quiet data/test/archive/general_test_packed/ar003.0698 output/test_actual/unpack_ar003.0698 \
            2>output/test_actual/unpack_ar003.0698_stderr", 
            allowed: [1])
    end
    it "should fail" do
      $?.exitstatus.should == 1
    end
    it "should write nothing on STDERR" do
      "unpack_ar003.0698_stderr".should be_an_empty_file
    end
    it "should not overwrite the file" do
      "output/test_actual/unpack_ar003.0698".should contain_content("foo")
    end
    after :all do
      backtrace
      exec_on_success("rm -f output/test_actual/unpack_ar003.0698")
      exec_on_success("rm -f output/test_actual/unpack_ar003.0698_stderr")
      exec_on_success("rm -rf data/test/archive/general_test_packed")
    end
  end
  context "to a file that already exists with --force" do
    before :all do
      exec("rm -f output/test_actual/unpack_ar003.0698")
      exec("rm -rf data/test/archive/general_test_packed")
      exec("echo foo > output/test_actual/unpack_ar003.0698")
      exec("cp -r data/test/archive/general_test_packed_init data/test/archive/general_test_packed")
      exec("bun unpack --force data/test/archive/general_test_packed/ar003.0698 output/test_actual/unpack_ar003.0698")
    end
    it "should match the expected output" do
      "unpack_ar003.0698".should match_expected_output_except_for(UNPACK_PATTERNS)
    end
    after :all do
      backtrace
      exec_on_success("rm -f output/test_actual/unpack_ar003.0698")
      exec_on_success("rm -rf data/test/archive/general_test_packed")
    end
  end
  context "with a text file" do
    context "with output to '-'" do
      before :all do
        exec("rm -f output/test_actual/unpack_ar003.0698")
        exec("rm -rf data/test/archive/general_test_packed")
        exec("cp -r data/test/archive/general_test_packed_init \
                    data/test/archive/general_test_packed")
        exec("bun unpack data/test/archive/general_test_packed/ar003.0698 - \
                  >output/test_actual/unpack_ar003.0698")
      end
      it "should match the expected output" do
        "unpack_ar003.0698".should match_expected_output_except_for(UNPACK_PATTERNS)
      end
      after :all do
        backtrace
        exec_on_success("rm -f output/test_actual/unpack_ar003.0698")
        exec_on_success("rm -rf data/test/archive/general_test_packed")
      end
    end
    context "with omitted output" do
      before :all do
        exec("rm -f output/test_actual/unpack_ar003.0698")
        exec("rm -rf data/test/archive/general_test_packed")
        exec("cp -r data/test/archive/general_test_packed_init \
                 data/test/archive/general_test_packed")
        exec("bun unpack data/test/archive/general_test_packed/ar003.0698 >output/test_actual/unpack_ar003.0698")
      end
      it "should match the expected output" do
        "unpack_ar003.0698".should match_expected_output_except_for(UNPACK_PATTERNS)
      end
      after :all do
        backtrace
        exec_on_success("rm -f output/test_actual/unpack_ar003.0698")
        exec_on_success("rm -rf data/test/archive/general_test_packed")
      end
    end
    context "from STDIN" do
      context "without tape name" do
        before :all do
          exec("rm -rf output/test_actual/unpack_stdin_ar003.0698")
          exec("rm -rf data/test/archive/general_test_packed")
          exec("cp -r data/test/archive/general_test_packed_init \
                  data/test/archive/general_test_packed")
          exec("cat data/test/archive/general_test_packed/ar003.0698 | \
                  bun unpack - >output/test_actual/unpack_stdin_ar003.0698")
        end
        it "should match the expected output" do
          "unpack_stdin_ar003.0698".should match_expected_output_except_for(UNPACK_PATTERNS)
        end
        after :all do
          backtrace
          exec_on_success("rm -rf output/test_actual/unpack_stdin_ar003.0698")
          exec_on_success("rm -rf data/test/archive/general_test_packed")
        end
      end
      context "with tape name" do
        before :all do
          exec("rm -f output/test_actual/unpack_ar003.0698")
          exec("rm -rf data/test/archive/general_test_packed")
          exec("cp -r data/test/archive/general_test_packed_init \
                  data/test/archive/general_test_packed")
          exec("cat data/test/archive/general_test_packed/ar003.0698 | \
                  bun unpack -t ar003.0698 - >output/test_actual/unpack_ar003.0698")
        end
        it "should match the expected output" do
          "unpack_ar003.0698".should match_expected_output_except_for(UNPACK_PATTERNS)
        end
        after :all do
          backtrace
          exec_on_success("rm -f output/test_actual/unpack_ar003.0698")
          exec_on_success("rm -rf data/test/archive/general_test_packed")
        end
      end
    end
    context "with output to a file" do
      before :all do
        exec("rm -f output/test_actual/unpack_ar003.0698")
        exec("rm -rf data/test/archive/general_test_packed")
        exec("cp -r data/test/archive/general_test_packed_init data/test/archive/general_test_packed")
        exec("bun unpack data/test/archive/general_test_packed/ar003.0698 output/test_actual/unpack_ar003.0698")
      end
      it "should match the expected output" do
        "unpack_ar003.0698".should match_expected_output_except_for(UNPACK_PATTERNS)
      end
      after :all do
        backtrace
        exec_on_success("rm -f output/test_actual/unpack_ar003.0698")
        exec_on_success("rm -rf data/test/archive/general_test_packed")
      end
    end
  end
  context "with a frozen file" do
    before :all do
      exec("rm -f output/test_actual/unpack_ar019.0175")
      exec("rm -rf data/test/archive/general_test_packed")
      exec("cp -r data/test/archive/general_test_packed_init data/test/archive/general_test_packed")
      exec("bun unpack data/test/archive/general_test_packed/ar019.0175 output/test_actual/unpack_ar019.0175")
    end
    it "should match the expected output" do
      "unpack_ar019.0175".should match_expected_output_except_for(UNPACK_PATTERNS)
    end
    after :all do
      backtrace
      exec_on_success("rm -f output/test_actual/unpack_ar019.0175")
      exec_on_success("rm -rf data/test/archive/general_test_packed")
    end
  end
  context "with a huffman file" do
    before :all do
      exec("rm -f output/test_actual/unpack_ar003.0701")
      exec("rm -rf data/test/archive/general_test_packed")
      exec("cp -r data/test/archive/general_test_packed_init data/test/archive/general_test_packed")
      exec("bun unpack data/test/archive/general_test_packed/ar003.0701 output/test_actual/unpack_ar003.0701")
    end
    it "should match the expected output" do
      "unpack_ar003.0701".should match_expected_output_except_for(UNPACK_PATTERNS)
    end
    after :all do
      backtrace
      exec_on_success("rm -f output/test_actual/unpack_ar003.0701")
      exec_on_success("rm -rf data/test/archive/general_test_packed")
    end
  end
  context "with an undecodable file" do
    context "with output to '-'" do
      before :all do
        exec("rm -f output/test_actual/unpack_ar010.1307")
        exec("cp -r data/test/archive/general_test_packed_init \
                    data/test/archive/general_test_packed")
        exec("bun unpack data/test/ar010.1307 - \
                  >output/test_actual/unpack_ar010.1307")
      end
      it "should match the expected output" do
        "unpack_ar010.1307".should match_expected_output_except_for(UNPACK_PATTERNS)
      end
      after :all do
        backtrace
        exec_on_success("rm -f output/test_actual/unpack_ar010.1307")
      end
    end
  end
  context "with a file with a bad time" do
    context "without --fix" do
      before :all do
        exec("rm -f output/test_actual/unpack_packed_with_bad_time")
        exec("rm -f output/test_actual/unpack_packed_with_bad_time_stderr.txt")
        exec("bun unpack data/test/packed_with_bad_time output/test_actual/unpack_packed_with_bad_time \
                  2>output/test_actual/unpack_packed_with_bad_time_stderr.txt", 
              allowed: [1])
      end
      it "should fail" do
        $?.exitstatus.should == 1
      end
      it "should not create the file" do
        file_should_not_exist("output/test_actual/unpack_packed_with_bad_time")
      end
      it "should write diagnostics on STDERR" do
        "unpack_packed_with_bad_time_stderr.txt".should match_expected_output
      end
      after :all do
        backtrace
        exec_on_success("rm -f output/test_actual/unpack_packed_with_bad_time")
        exec_on_success("rm -f output/test_actual/unpack_packed_with_bad_time_stderr.txt")
      end
    end
    context "with --fix" do
      before :all do
        exec("rm -f output/test_actual/unpack_packed_with_bad_time")
        exec("rm -f output/test_actual/unpack_packed_with_bad_time_stderr.txt")
        @before_time = Time.now
        exec("bun unpack --fix data/test/packed_with_bad_time output/test_actual/unpack_packed_with_bad_time \
                  2>output/test_actual/unpack_packed_with_bad_time_stderr.txt")
        @after_time = Time.now
      end
      it "should create the file" do
        "unpack_packed_with_bad_time".should match_expected_output_except_for(UNPACK_AND_TIME_PATTERNS)
      end
      it "should have today's date" do
        time_string = `bun show time output/test_actual/unpack_packed_with_bad_time`.chomp
        file_date = Date.strptime(time_string[0,10])
        file_date.should be >= @before_time.to_date
        file_date.should be <= @after_time.to_date
      end
      it "should write nothing on STDERR" do
        "output/test_actual/unpack_packed_with_bad_time_stderr.txt".should be_an_empty_file
      end
      after :all do
        backtrace
        exec_on_success("rm -f output/test_actual/unpack_packed_with_bad_time")
        exec_on_success("rm -f output/test_actual/unpack_packed_with_bad_time_stderr.txt")
      end
    end
  end
  context "with a file with a bad bcw" do
    context "without --fix" do
      before :all do
        exec("rm -f output/test_actual/unpack_packed_with_bad_bcw")
        exec("rm -f output/test_actual/unpack_packed_with_bad_bcw_stderr.txt")
        exec("bun unpack data/test/packed_with_bad_bcw output/test_actual/unpack_packed_with_bad_bcw \
                  2>output/test_actual/unpack_packed_with_bad_bcw_stderr.txt", 
              allowed: [1])
      end
      it "should fail" do
        $?.exitstatus.should == 1
      end
      it "should not create the file" do
        file_should_not_exist("output/test_actual/unpack_packed_with_bad_bcw")
      end
      it "should write diagnostics on STDERR" do
        "unpack_packed_with_bad_bcw_stderr.txt".should match_expected_output
      end
      after :all do
        backtrace
        exec_on_success("rm -f output/test_actual/unpack_packed_with_bad_bcw")
        exec_on_success("rm -f output/test_actual/unpack_packed_with_bad_bcw_stderr.txt")
      end
    end
    context "with --fix" do
      before :all do
        exec("rm -f output/test_actual/unpack_packed_with_bad_bcw")
        exec("rm -f output/test_actual/unpack_packed_with_bad_bcw_fix_stderr.txt")
        exec("bun unpack --fix data/test/packed_with_bad_bcw output/test_actual/unpack_packed_with_bad_bcw \
                  2>output/test_actual/unpack_packed_with_bad_bcw_fix_stderr.txt")
      end
      it "should create the file" do
        "unpack_packed_with_bad_bcw".should match_expected_output_except_for(UNPACK_PATTERNS)
      end
      it "should write a message on STDERR" do
        "unpack_packed_with_bad_bcw_fix_stderr.txt".should match_expected_output
      end
      after :all do
        backtrace
        exec_on_success("rm -f output/test_actual/unpack_packed_with_bad_bcw")
        exec_on_success("rm -f output/test_actual/unpack_packed_with_bad_bcw_fix_stderr.txt")
      end
    end
  end
end