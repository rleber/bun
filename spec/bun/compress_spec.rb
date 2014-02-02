#!/usr/bin/env rvm-ruby 1.9.3
# -*- encoding: us-ascii -*-

describe "compress" do
  context "to a new directory" do
    before :all do
      exec("rm -rf data/test/archive/compress")
      exec("rm -rf output/test_actual/compress")
      exec("rm -rf output/test_actual/compress_files.txt")
      exec("rm -rf output/test_actual/compress_files_before.txt")
      exec("rm -rf output/test_actual/compress_stdout.txt")
      exec("rm -rf output/test_actual/compress_stderr.txt")
      exec("cp -r data/test/archive/compress_init data/test/archive/compress")
      exec("find data/test/archive/compress -print >output/test_actual/compress_files_before.txt")
      exec("bun compress data/test/archive/compress output/test_actual/compress \
                2>output/test_actual/compress_stderr.txt >output/test_actual/compress_stdout.txt")
      exec("find output/test_actual/compress -print >output/test_actual/compress_files.txt")
    end
    it "should create the proper files" do
      "compress_files.txt".should match_expected_output
    end
    it "should leave the original directory alone" do
      "compress_files_before.txt".should match_expected_output
    end
    it "should write the proper messages on STDERR" do
      "compress_stderr.txt".should match_expected_output
    end
    it "should write nothing on STDOUT" do
      "output/test_actual/compress_stdout.txt".should be_an_empty_file
    end
    after :all do
      backtrace
      exec_on_success("rm -rf data/test/archive/compress")
      exec_on_success("rm -rf output/test_actual/compress")
      exec_on_success("rm -rf output/test_actual/compress_files.txt")
      exec_on_success("rm -rf output/test_actual/compress_files_before.txt")
      exec_on_success("rm -rf output/test_actual/compress_stdout.txt")
      exec_on_success("rm -rf output/test_actual/compress_stderr.txt")
    end
  end
  context "to a new directory --quiet" do
    before :all do
      exec("rm -rf data/test/archive/compress")
      exec("rm -rf output/test_actual/compress")
      exec("rm -rf output/test_actual/compress_files.txt")
      exec("rm -rf output/test_actual/compress_files_before.txt")
      exec("rm -rf output/test_actual/compress_stdout.txt")
      exec("rm -rf output/test_actual/compress_stderr.txt")
      exec("cp -r data/test/archive/compress_init data/test/archive/compress")
      exec("find data/test/archive/compress -print >output/test_actual/compress_files_before.txt")
      exec("bun compress data/test/archive/compress output/test_actual/compress \
                2>output/test_actual/compress_stderr.txt >output/test_actual/compress_stdout.txt")
      exec("find output/test_actual/compress -print >output/test_actual/compress_files.txt")
    end
    it "should create the proper files" do
      "compress_files.txt".should match_expected_output
    end
    it "should leave the original directory alone" do
      "compress_files_before.txt".should match_expected_output
    end
    it "should write nothing on STDERR" do
      "compress_stderr.txt".should be_an_empty_file
    end
    it "should write nothing on STDOUT" do
      "output/test_actual/compress_stdout.txt".should be_an_empty_file
    end
    after :all do
      backtrace
      exec_on_success("rm -rf data/test/archive/compress")
      exec_on_success("rm -rf output/test_actual/compress")
      exec_on_success("rm -rf output/test_actual/compress_files.txt")
      exec_on_success("rm -rf output/test_actual/compress_files_before.txt")
      exec_on_success("rm -rf output/test_actual/compress_stdout.txt")
      exec_on_success("rm -rf output/test_actual/compress_stderr.txt")
    end
  end
  context "to an existing directory" do
    before :all do
      exec("rm -rf data/test/archive/compress")
      exec("rm -rf output/test_actual/compress")
      exec("rm -rf output/test_actual/compress_files_existing.txt")
      exec("rm -rf output/test_actual/compress_stdout_existing.txt")
      exec("rm -rf output/test_actual/compress_stderr_existing.txt")
      exec("cp -r data/test/archive/compress_init data/test/archive/compress")
      exec("mkdir output/test_actual/compress")
      exec("bun compress data/test/archive/compress output/test_actual/compress \
                2>output/test_actual/compress_stderr_existing.txt \
                >output/test_actual/compress_stdout_existing.txt",
                allowed: [1])
      @exitstatus = $?.exitstatus
      exec("find output/test_actual/compress -print >output/test_actual/compress_files_existing.txt")
    end
    it "should fail" do
      @exitstatus.should == 1
    end
    it "should not create any files" do
      "compress_files_existing.txt".should match_expected_output
    end
    it "should write the proper messages on STDERR" do
      "compress_stderr_existing.txt".should match_expected_output
    end
    it "should write nothing on STDOUT" do
      "output/test_actual/compress_stdout_existing.txt".should be_an_empty_file
    end
    after :all do
      backtrace
      exec_on_success("rm -rf data/test/archive/compress")
      exec_on_success("rm -rf output/test_actual/compress")
      exec_on_success("rm -rf output/test_actual/compress_files.txt")
      exec_on_success("rm -rf output/test_actual/compress_files_before.txt")
      exec_on_success("rm -rf output/test_actual/compress_stdout.txt")
      exec_on_success("rm -rf output/test_actual/compress_stderr.txt")
    end
  end
  context "to an existing directory with --force" do
    before :all do
      exec("rm -rf data/test/archive/compress")
      exec("rm -rf output/test_actual/compress")
      exec("rm -rf output/test_actual/compress_files.txt")
      exec("rm -rf output/test_actual/compress_files_before.txt")
      exec("rm -rf output/test_actual/compress_stdout.txt")
      exec("rm -rf output/test_actual/compress_stderr.txt")
      exec("mkdir output/test_actual/compress")
      exec("cp -r data/test/archive/compress_init data/test/archive/compress")
      exec("find data/test/archive/compress -print >output/test_actual/compress_files_before.txt")
      exec("bun compress --force data/test/archive/compress output/test_actual/compress \
                2>output/test_actual/compress_stderr.txt >output/test_actual/compress_stdout.txt")
      exec("find output/test_actual/compress -print >output/test_actual/compress_files.txt")
    end
    it "should create the proper files" do
      "compress_files.txt".should match_expected_output
    end
    it "should leave the original directory alone" do
      "compress_files_before.txt".should match_expected_output
    end
    it "should write the proper messages on STDERR" do
      "compress_stderr.txt".should match_expected_output
    end
    it "should write nothing on STDOUT" do
      "output/test_actual/compress_stdout.txt".should be_an_empty_file
    end
    after :all do
      backtrace
      exec_on_success("rm -rf data/test/archive/compress")
      exec_on_success("rm -rf output/test_actual/compress")
      exec_on_success("rm -rf output/test_actual/compress_files.txt")
      exec_on_success("rm -rf output/test_actual/compress_files_before.txt")
      exec_on_success("rm -rf output/test_actual/compress_stdout.txt")
      exec_on_success("rm -rf output/test_actual/compress_stderr.txt")
    end
  end
  context "to the same directory" do
    before :all do
      exec("rm -rf data/test/archive/compress")
      exec("rm -rf output/test_actual/compress_files_inplace.txt")
      exec("rm -rf output/test_actual/compress_files_before.txt")
      exec("rm -rf output/test_actual/compress_stdout_inplace.txt")
      exec("rm -rf output/test_actual/compress_stderr_inplace.txt")
      exec("cp -r data/test/archive/compress_init data/test/archive/compress")
      exec("find data/test/archive/compress -print >output/test_actual/compress_files_before.txt")
      exec("bun compress data/test/archive/compress \
                2>output/test_actual/compress_stderr_inplace.txt >output/test_actual/compress_stdout_inplace.txt")
      exec("find data/test/archive/compress -print >output/test_actual/compress_files_inplace.txt")
    end
    it "should create the proper files" do
      "compress_files_inplace.txt".should match_expected_output
    end
    it "should leave the original directory alone" do
      "compress_files_before.txt".should match_expected_output
    end
    it "should write the proper messages on STDERR" do
      "compress_stderr_inplace.txt".should match_expected_output
    end
    it "should write nothing on STDOUT" do
      "output/test_actual/compress_stdout_inplace.txt".should be_an_empty_file
    end
    after :all do
      backtrace
      exec_on_success("rm -rf data/test/archive/compress")
      exec_on_success("rm -rf output/test_actual/compress_files_inplace.txt")
      exec_on_success("rm -rf output/test_actual/compress_files_before.txt")
      exec_on_success("rm -rf output/test_actual/compress_stdout_inplace.txt")
      exec_on_success("rm -rf output/test_actual/compress_stderr_inplace.txt")
    end
  end
end
