#!/usr/bin/env rvm-ruby 1.9.3
# -*- encoding: us-ascii -*-

describe "bake" do
  # TODO bake should be tested with decoded files 
  # TODO Bake should allow a shard specifier via -S
  context "with packed file" do
    before :all do
      exec("rm -f output/test_actual/bake_ar003.0698")
      exec("bun bake data/test/ar003.0698 \
                >output/test_actual/bake_ar003.0698")
    end
    it "should match the expected output" do
      "bake_ar003.0698".should match_expected_output
    end
    after :all do
      backtrace
      exec_on_success("rm -f output/test_actual/bake_ar003.0698")
    end
  end
  context "with unpacked file" do
    before :all do
      exec("rm -f output/test_actual/bake_ar003.0698")
      exec("bun bake #{TEST_ARCHIVE}/ar003.0698.bun \
                >output/test_actual/bake_ar003.0698")
    end
    it "should match the expected output" do
      "bake_ar003.0698".should match_expected_output
    end
    after :all do
      backtrace
      exec_on_success("rm -f output/test_actual/bake_ar003.0698")
    end
  end
  context "with unpacked file and --shard" do
    before :all do
      exec("rm -f output/test_actual/bake_ar074.1174_1.3b")
      exec("bun bake --shard 1.3b data/test/ar074.1174.bun \
                >output/test_actual/bake_ar074.1174_1.3b")
    end
    it "should match the expected output" do
      "bake_ar074.1174_1.3b".should match_expected_output
    end
    after :all do
      backtrace
      exec_on_success("rm -f output/test_actual/bake_ar074.1174_1.3b")
    end
  end
  context "with unpacked file and --scrub" do
    before :all do
      exec("rm -f output/test_actual/bake_ar074.1174_1.3b_scrub")
      exec("bun bake --scrub data/test/ar074.1174.bun[1.3b] \
                >output/test_actual/bake_ar074.1174_1.3b_scrub")
    end
    it "should match the expected output" do
      "bake_ar074.1174_1.3b_scrub".should match_expected_output
    end
    after :all do
      backtrace
      exec_on_success("rm -f output/test_actual/bake_ar074.1174_1.3b_scrub")
    end
  end
  context "with decoded file" do
    before :all do
      exec("rm -f output/test_actual/bake_decoded_file.txt")
      exec("bun bake data/test/decoded_file.txt \
                >output/test_actual/bake_decoded_file.txt")
    end
    it "should match the expected output" do
      "bake_decoded_file.txt".should match_expected_output
    end
    after :all do
      backtrace
      exec_on_success("rm -f output/test_actual/bake_decoded_file.txt")
    end
  end
  context "with decoded file and --index" do
    before :all do
      exec("rm -f output/test_actual/bake_decoded_file.txt")
      exec("rm -f output/test_actual/bake_decoded_file_index.yml")
      exec("bun bake data/test/decoded_file.txt --index output/test_actual/bake_decoded_file_index.yml \
                >output/test_actual/bake_decoded_file.txt")
    end
    it "should match the expected output" do
      "bake_decoded_file.txt".should match_expected_output
    end
    it "should create the expected index file" do
      "bake_decoded_file_index.yml".should match_expected_output
    end
    after :all do
      backtrace
      exec_on_success("rm -f output/test_actual/bake_decoded_file.txt")
      exec_on_success("rm -f output/test_actual/bake_decoded_file_index.yml")
    end
  end
  context "with an existing file" do
    before :all do
      exec("rm -f output/test_actual/bake_decoded_file.txt")
      exec("rm -f output/test_actual/bake_decoded_exists_stderr.txt")
      exec("echo foo >output/test_actual/bake_decoded_file.txt")
      exec("bun bake data/test/decoded_file.txt output/test_actual/bake_decoded_file.txt \
                2>output/test_actual/bake_decoded_exists_stderr.txt ", allowed: [1])
      @exitstatus = $?.exitstatus
    end
    it "should fail" do
      @exitstatus.should == 1
    end
    it "should not overwrite the existing file" do
      "output/test_actual/bake_decoded_file.txt".should contain_content('foo')
    end
    it "should write the proper messages on STDERR" do
      "bake_decoded_exists_stderr.txt".should match_expected_output
    end
    after :all do
      backtrace
      exec_on_success("rm -f output/test_actual/bake_decoded_file.txt")
      exec_on_success("rm -f output/test_actual/bake_decoded_exists_stderr.txt")
    end
  end
  context "with an existing file and --quiet" do
    before :all do
      exec("rm -f output/test_actual/bake_decoded_file.txt")
      exec("rm -f output/test_actual/bake_decoded_exists_stderr.txt")
      exec("echo foo >output/test_actual/bake_decoded_file.txt")
      exec("bun bake --quiet data/test/decoded_file.txt output/test_actual/bake_decoded_file.txt \
                2>output/test_actual/bake_decoded_exists_stderr.txt ", allowed: [1])
      @exitstatus = $?.exitstatus
    end
    it "should fail" do
      @exitstatus.should == 1
    end
    it "should not overwrite the existing file" do
      "output/test_actual/bake_decoded_file.txt".should contain_content('foo')
    end
    it "should write nothing on STDERR" do
      "bake_decoded_exists_stderr.txt".should be_an_empty_file
    end
    after :all do
      backtrace
      exec_on_success("rm -f output/test_actual/bake_decoded_file.txt")
      exec_on_success("rm -f output/test_actual/bake_decoded_exists_stderr.txt")
    end
  end
  context "with an existing file and --force" do
    before :all do
      exec("rm -f output/test_actual/bake_decoded_file.txt")
      exec("echo foo >output/test_actual/bake_decoded_file.txt")
      exec("bun bake --force data/test/decoded_file.txt output/test_actual/bake_decoded_file.txt")
    end
    it "should match the expected output" do
      "bake_decoded_file.txt".should match_expected_output
    end
    after :all do
      backtrace
      exec_on_success("rm -f output/test_actual/bake_decoded_file.txt")
    end
  end
  context "with an undecodable file" do
    before :all do
      exec("rm -f output/test_actual/bake_undecodable_file.txt")
      exec("bun bake data/test/undecodable_decoded_file \
                >output/test_actual/bake_undecodable_file.txt")
    end
    it "should match the expected output" do
      "bake_undecodable_file.txt".should match_expected_output
    end
    after :all do
      backtrace
      exec_on_success("rm -f output/test_actual/bake_undecodable_file.txt")
    end
  end
end
