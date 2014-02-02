#!/usr/bin/env rvm-ruby 1.9.3
# -*- encoding: us-ascii -*-

describe "same" do
  before :all do
    exec("rm -rf output/test_actual/same_stdout.txt")
    exec("bun same digest data/test/archive/same >output/test_actual/same_stdout.txt")
  end
  it "should produce the proper output" do
    "same_stdout.txt".should match_expected_output
  end
  after :all do
    backtrace
    exec_on_success("rm -rf output/test_actual/same_stdout.txt")
  end
end
