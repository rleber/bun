#!/usr/bin/env rvm-ruby 1.9.3
# -*- encoding: us-ascii -*-

describe "archive decode" do
  context "normal archive" do
    before :all do
      exec("rm -rf data/test/archive/decode_source")
      exec("rm -rf data/test/archive/decode_archive")
      exec("cp -r data/test/archive/decode_source_init data/test/archive/decode_source")
      exec("bun archive decode data/test/archive/decode_source data/test/archive/decode_archive \
                2>output/test_actual/archive_decode_stderr.txt >output/test_actual/archive_decode_stdout.txt")
    end
    it "should create a tapes directory" do
      file_should_exist "data/test/archive/decode_archive"
    end
    it "should write nothing on stdout" do
      'output/test_actual/archive_decode_stdout.txt'.should be_an_empty_file
    end
    it "should write file decoding messages on stderr" do
      "archive_decode_stderr.txt".should match_expected_output
    end
    it "should create the appropriate files" do
      exec('find data/test/archive/decode_archive -print >output/test_actual/archive_decode_files.txt')
      'archive_decode_files.txt'.should match_expected_output
    end
    after :all do
      backtrace
      exec_on_success("rm -rf data/test/archive/decode_source")
      exec_on_success("rm -rf data/test/archive/decode_archive")
      exec_on_success("rm -f output/test_actual/archive_decode_stderr.txt")
      exec_on_success("rm -f output/test_actual/archive_decode_stdout.txt")
      exec_on_success("rm -f output/test_actual/archive_decode_files.txt")
    end
  end

  context "mixed archive" do
    before :all do
      exec("rm -rf data/test/archive/mixed_formats")
      exec("rm -rf output/test_actual/mixed_formats_decode")
      exec("rm -f output/test_actual/mixed_formats_archive_decode.txt")
      exec("rm -f output/test_actual/mixed_formats_archive_diff.txt")
      exec("cp -r data/test/archive/mixed_formats_init data/test/archive/mixed_formats")
      exec("bun archive decode data/test/archive/mixed_formats output/test_actual/mixed_formats_decode 2>/dev/null \
                >/dev/null")
    end
    it "should create the proper files" do
      exec "find output/test_actual/mixed_formats_decode -print >output/test_actual/mixed_formats_archive_decode.txt"
      'mixed_formats_archive_decode.txt'.should match_expected_output
    end
    it "should write the proper content" do
      "mixed_formats_decode/fass/idallen/vector/tape.ar003.0698.txt".should match_expected_output_except_for(DECODE_PATTERNS)
      "mixed_formats_decode/fass/idallen/huffhart/tape.ar003.0701_19761122.txt".should match_expected_output_except_for(DECODE_PATTERNS)
      "mixed_formats_decode/fass/1986/script/script.f_19860213/1-1/tape.ar120.0740_19860213_134229.txt".should \
          match_expected_output
      "mixed_formats_decode/fass/script/tape.ar004.0642_19770224.txt".should match_expected_output_except_for(DECODE_PATTERNS)
    end
    after :all do
      backtrace
      exec_on_success("rm -rf data/test/archive/mixed_formats")
      exec_on_success("rm -rf output/test_actual/mixed_formats_decode")
      exec_on_success("rm -f output/test_actual/mixed_formats_archive_decode.txt")
      exec_on_success("rm -f output/test_actual/mixed_formats_archive_diff.txt")
    end
  end
end
