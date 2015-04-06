#!/usr/bin/env rvm-ruby 1.9.3
# -*- encoding: us-ascii -*-

describe "describe" do
  describe "with normal file" do
    before :all do
      exec("rm -rf output/test_actual/describe_ar003.0698")
      exec("bun describe #{TEST_ARCHIVE}/ar003.0698.bun >output/test_actual/describe_ar003.0698")
    end
    it "should match the expected output" do
      "describe_ar003.0698".should match_expected_output_except_for(DESCRIBE_PATTERNS)
    end
    after :all do
      backtrace
      exec_on_success("rm -rf output/test_actual/describe_ar003.0698")
    end
  end
  describe "with frozen file" do
    before :all do
      exec("rm -rf output/test_actual/describe_ar025.0634")
      exec("bun describe #{TEST_ARCHIVE}/ar025.0634.bun >output/test_actual/describe_ar025.0634")
    end
    it "should match the expected output (including quoting)" do
      "describe_ar025.0634".should match_expected_output_except_for(DESCRIBE_PATTERNS)
    end
    after :all do
      backtrace
      exec_on_success("rm -rf output/test_actual/describe_ar025.0634")
    end
  end

  context "functioning outside the base directory" do
    before :each do
      raise RuntimeError, "In unexpected working directory: #{Dir.pwd}" \
        unless File.expand_path(Dir.pwd) == File.expand_path(File.join(File.dirname(__FILE__),'..','..'))
      @original_dir = Dir.pwd
    end
    it "should start in the base directory" do
      File.expand_path(Dir.pwd).should == File.expand_path(File.join(File.dirname(__FILE__),'..','..'))
    end
    it "should function okay in a different directory" do
      exec("cd ~ ; bun describe #{TEST_ARCHIVE}/ar003.0698.bun")
      $?.exitstatus.should == 0
    end
    after :each do
      Dir.chdir(@original_dir) if @original_dir
      raise RuntimeError, "Not back in normal working directory: #{Dir.pwd}" \
        unless File.expand_path(Dir.pwd) == File.expand_path(File.join(File.dirname(__FILE__),'..','..'))
    end
    after :all do
      backtrace
    end
  end
  context "packed file (ar003.0698)" do
    before :all do
      exec("cp -r data/test/archive/mixed_formats_init data/test/archive/mixed_formats")
      exec("rm -rf output/test_actual/mixed_formats_describe_ar003.0698")
      exec("bun describe data/test/archive/mixed_formats/ar003.0698 >output/test_actual/mixed_formats_describe_ar003.0698")
    end
    it "should match the expected output" do
      "mixed_formats_describe_ar003.0698".should match_expected_output
    end
    after :all do
      backtrace
      exec_on_success("cp -r data/test/archive/mixed_formats_init data/test/archive/mixed_formats")
      exec_on_success("rm -rf output/test_actual/mixed_formats_describe_ar003.0698")
    end      
  end
  context "unpacked file (ar003.0701.bun)" do
    before :all do
      exec("cp -r data/test/archive/mixed_formats_init data/test/archive/mixed_formats")
      exec("rm -rf output/test_actual/mixed_formats_describe_ar003.0701.bun")
      exec("bun describe data/test/archive/mixed_formats/ar003.0701.bun >output/test_actual/mixed_formats_describe_ar003.0701.bun")
    end
    it "should match the expected output" do
      "mixed_formats_describe_ar003.0701.bun".should match_expected_output_except_for(DESCRIBE_PATTERNS)
    end
    after :all do
      backtrace
      exec_on_success("cp -r data/test/archive/mixed_formats_init data/test/archive/mixed_formats")
      exec_on_success("rm -rf output/test_actual/mixed_formats_describe_ar003.0701.bun")
    end      
  end
  context "decoded file (fass/script/tape.ar004.0642_19770224)" do
    before :all do
      exec("cp -r data/test/archive/mixed_formats_init data/test/archive/mixed_formats")
      exec("rm -rf output/test_actual/mixed_formats_describe_fass_script_tape.ar004.0642_19770224")
      exec("bun describe data/test/archive/mixed_formats/fass/script/tape.ar004.0642_19770224 >output/test_actual/mixed_formats_describe_fass_script_tape.ar004.0642_19770224")
    end
    it "should match the expected output" do
      "mixed_formats_describe_fass_script_tape.ar004.0642_19770224".should match_expected_output_except_for(DESCRIBE_WITH_DECODE_PATTERNS)
    end
    after :all do
      backtrace
      exec_on_success("cp -r data/test/archive/mixed_formats_init data/test/archive/mixed_formats")
      exec_on_success("rm -rf output/test_actual/mixed_formats_describe_fass_script_tape.ar004.0642_19770224")
    end      
  end
  context "baked file (fass/1986/script/script.f_19860213/1-1/tape.ar120.0740_19860213_134229)" do
    before :all do
      exec("cp -r data/test/archive/mixed_formats_init data/test/archive/mixed_formats")
      exec("rm -rf output/test_actual/mixed_formats_describe_clean_fass_1986_script_script.f_19860213_1-1_tape.ar120.0740_19860213_134229")
      exec("bun describe data/test/archive/mixed_formats/fass/1986/script/script.f_19860213/1-1/tape.ar120.0740_19860213_134229 >output/test_actual/mixed_formats_describe_fass_1986_script_script.f_19860213_1-1_tape.ar120.0740_19860213_134229")
    end
    it "should match the expected output" do
      "mixed_formats_describe_fass_1986_script_script.f_19860213_1-1_tape.ar120.0740_19860213_134229".should match_expected_output
    end
    after :all do
      backtrace
      exec_on_success("cp -r data/test/archive/mixed_formats_init data/test/archive/mixed_formats")
      exec_on_success("rm -rf output/test_actual/mixed_formats_describe_clean_fass_1986_script_script.f_19860213_1-1_tape.ar120.0740_19860213_134229")
    end      
  end
end  
