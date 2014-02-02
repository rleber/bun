#!/usr/bin/env rvm-ruby 1.9.3
# -*- encoding: us-ascii -*-

describe "archive bake" do
  before :all do
    exec("rm -rf data/test/archive/mixed_formats")
    exec("rm -rf output/test_actual/mixed_formats_bake")
    exec("rm -f output/test_actual/mixed_formats_archive_bake.txt")
    exec("rm -f output/test_actual/mixed_formats_archive_diff.txt")
    exec("cp -r data/test/archive/mixed_formats_init data/test/archive/mixed_formats")
    exec("bun archive bake data/test/archive/mixed_formats output/test_actual/mixed_formats_bake 2>/dev/null \
              >/dev/null")
  end
  it "should create the proper files" do
    exec "find output/test_actual/mixed_formats_bake -print >output/test_actual/mixed_formats_archive_bake.txt"
    'mixed_formats_archive_bake.txt'.should match_expected_output
  end
  it "should write the proper content" do
    "mixed_formats_bake/ar003.0698".should match_expected_output
    "mixed_formats_bake/ar003.0701.bun".should match_expected_output
    "mixed_formats_bake/fass/1986/script/script.f_19860213/1-1/tape.ar120.0740_19860213_134229.txt".should \
        match_expected_output
    "mixed_formats_bake/fass/script/tape.ar004.0642_19770224.txt".should match_expected_output
  end
  after :all do
    backtrace
    exec_on_success("rm -rf data/test/archive/mixed_formats")
    exec_on_success("rm -rf output/test_actual/mixed_formats_bake")
    exec_on_success("rm -f output/test_actual/mixed_formats_archive_bake.txt")
    exec_on_success("rm -f output/test_actual/mixed_formats_archive_diff.txt")
  end
end
