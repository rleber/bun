#!/usr/bin/env rvm-ruby 1.9.3
# -*- encoding: us-ascii -*-

describe "mark" do
  context "with no output file" do
    before :all do
      exec "rm -f data/test/mark_source.bun"
      exec "cp data/test/mark_source_init.bun data/test/mark_source.bun"
      exec "bun describe data/test/mark_source.bun >output/test_actual/mark_source_before"
      exec "bun mark -t \" foo : bar , named:'abc,d\\\\'ef '\" data/test/mark_source.bun"
      exec "bun describe data/test/mark_source.bun >output/test_actual/mark_source_after"
    end
    it "should have the expected input" do
      "mark_source_before".should match_expected_output_except_for(DESCRIBE_PATTERNS)
    end
    it "should create the expected marks in the existing file" do
      "mark_source_after".should match_expected_output_except_for(DESCRIBE_PATTERNS)
    end
    after :all do
      backtrace
      exec_on_success "rm -f data/test/mark_source.bun"
      exec_on_success "rm -f output/test_actual/mark_source_before"
      exec_on_success "rm -f output/test_actual/mark_source_after"
    end
  end
  context "with an output file" do
    before :all do
      exec "rm -f data/test/mark_source.bun"
      exec "cp data/test/mark_source_init.bun data/test/mark_source.bun"
      exec "bun describe data/test/mark_source.bun >output/test_actual/mark_source_before"
      exec "rm -f data/test/mark_result.bun"
      exec "bun mark -t \" foo : bar , named:'abc,d\\\\'ef '\" \
                data/test/mark_source.bun data/test/mark_result.bun"
      exec "bun describe data/test/mark_source.bun >output/test_actual/mark_source_after"
      exec "bun describe data/test/mark_result.bun >output/test_actual/mark_result_after"
    end
    it "should have the expected input" do
      "mark_source_before".should match_expected_output_except_for(DESCRIBE_PATTERNS)
    end
    it "should create the new file" do
      file_should_exist "data/test/mark_result.bun"
    end
    it "should create the expected marks in the new file" do
      "mark_result_after".should match_expected_output_except_for(DESCRIBE_PATTERNS)
    end
    it "should have leave the existing file unchanged" do
      "output/test_actual/mark_source_after".should match_file('output/test_actual/mark_source_before')
    end
    after :all do
      backtrace
      exec_on_success "rm -f data/test/mark_source.bun"
      exec_on_success "rm -f data/test/mark_result.bun"
      exec_on_success "rm -f output/test_actual/mark_source_before"
      exec_on_success "rm -f output/test_actual/mark_source_after"
      exec_on_success "rm -f output/test_actual/mark_result_after"
    end
  end
  context "with '-' as output file" do
    before :all do
      exec "rm -f data/test/mark_source.bun"
      exec "cp data/test/mark_source_init.bun data/test/mark_source.bun"
      exec "bun describe data/test/mark_source.bun >output/test_actual/mark_source_before"
      exec "rm -f output/test_actual/mark_result.bun"
      exec "bun mark -t \" foo : bar , named:'abc,d\\\\'ef '\" \
                data/test/mark_source.bun - >output/test_actual/mark_result.bun"
      exec "bun describe data/test/mark_source.bun >output/test_actual/mark_source_after"
      exec "bun describe output/test_actual/mark_result.bun >output/test_actual/mark_result_after"
    end
    it "should have the expected input" do
      "mark_source_before".should match_expected_output_except_for(DESCRIBE_PATTERNS)
    end
    it "should create the expected marks on STDOUT" do
      "mark_result_after".should match_expected_output_except_for(DESCRIBE_PATTERNS)
    end
    it "should have leave the existing file unchanged" do
      "output/test_actual/mark_source_after".should match_file('output/test_actual/mark_source_before')
    end
    after :all do
      backtrace
      exec_on_success "rm -f data/test/mark_source.bun"
      exec_on_success "rm -f output/test_actual/mark_result.bun"
      exec_on_success "rm -f output/test_actual/mark_source_before"
      exec_on_success "rm -f output/test_actual/mark_source_after"
      exec_on_success "rm -f output/test_actual/mark_result_after"
    end
  end
  context "with '-' as input file" do
    before :all do
      exec "rm -f data/test/mark_source.bun"
      exec "cp data/test/mark_source_init.bun data/test/mark_source.bun"
      exec "bun describe data/test/mark_source.bun >output/test_actual/mark_source_before"
      exec "rm -f data/test/mark_result.bun"
      exec "cat data/test/mark_source.bun | \
            bun mark -t \" foo : bar , named:'abc,d\\\\'ef '\" \
                - data/test/mark_result.bun"
      exec "bun describe data/test/mark_source.bun >output/test_actual/mark_source_after"
      exec "bun describe data/test/mark_result.bun >output/test_actual/mark_result_after"
    end
    it "should have the expected input" do
      "mark_source_before".should match_expected_output_except_for(DESCRIBE_PATTERNS)
    end
    it "should create the new file" do
      file_should_exist "data/test/mark_result.bun"
    end
    it "should create the expected marks in the new file" do
      "mark_result_after".should match_expected_output_except_for(DESCRIBE_PATTERNS)
    end
    it "should have leave the existing file unchanged" do
      "output/test_actual/mark_source_after".should match_file('output/test_actual/mark_source_before')
    end
    after :all do
      backtrace
      exec_on_success "rm -f data/test/mark_source.bun"
      exec_on_success "rm -f data/test/mark_result.bun"
      exec_on_success "rm -f output/test_actual/mark_source_before"
      exec_on_success "rm -f output/test_actual/mark_source_after"
      exec_on_success "rm -f output/test_actual/mark_result_after"
    end
  end
end
