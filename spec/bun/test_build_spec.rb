#!/usr/bin/env rvm-ruby 1.9.3
# -*- encoding: us-ascii -*-

describe "test build" do
  context "without --quiet" do
    before :all do
      exec("rm -rf output/test_actual/test_build_files.txt")
      exec("rm -rf output/test_actual/test_build_stdout.txt")
      exec("rm -rf output/test_actual/test_build_stderr.txt")
      exec("bun test build \
                2>output/test_actual/test_build_stderr.txt >output/test_actual/test_build_stdout.txt")
      exec("find data/test -print >output/test_actual/test_build_files.txt")
    end
    it "should create the proper files" do
      "test_build_files.txt".should match_expected_output
    end
    it "should write the proper messages on STDERR" do
      "test_build_stderr.txt".should match_expected_output
    end
    it "should write nothing on STDOUT" do
      "output/test_actual/test_build_stdout.txt".should be_an_empty_file
    end
    after :all do
      backtrace
      exec_on_success("rm -rf output/test_actual/test_build_files.txt")
      exec_on_success("rm -rf output/test_actual/test_build_stdout.txt")
      exec_on_success("rm -rf output/test_actual/test_build_stderr.txt")
    end
  end
  context "without --quiet" do
    before :all do
      exec("rm -rf output/test_actual/test_build_files.txt")
      exec("rm -rf output/test_actual/test_build_stdout.txt")
      exec("rm -rf output/test_actual/test_build_stderr.txt")
      exec("bun test build --quiet \
                2>output/test_actual/test_build_stderr.txt >output/test_actual/test_build_stdout.txt")
      exec("find data/test -print >output/test_actual/test_build_files.txt")
    end
    it "should create the proper files" do
      "test_build_files.txt".should match_expected_output
    end
    it "should write nothing on STDERR" do
      "test_build_stderr.txt".should be_an_empty_file
    end
    it "should write nothing on STDOUT" do
      "output/test_actual/test_build_stdout.txt".should be_an_empty_file
    end
    after :all do
      backtrace
      exec_on_success("rm -rf output/test_actual/test_build_files.txt")
      exec_on_success("rm -rf output/test_actual/test_build_stdout.txt")
      exec_on_success("rm -rf output/test_actual/test_build_stderr.txt")
    end
  end
end
