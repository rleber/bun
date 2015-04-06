#!/usr/bin/env rvm-ruby 1.9.3
# -*- encoding: us-ascii -*-

describe "scrub" do
  [
    {
      :title=>"basic",
      :command=>"scrub data/test/scrub_test.txt"
    },
    {
      :title=>"from STDIN",
      :command=>"\\cat data/test/scrub_test.txt | bun scrub -"
    },
    {
      :title=>"--tabs",
      :command=>"scrub --tabs 20 data/test/scrub_test.txt"
    },
  ].each do |test|
    exec_test_hash "scrub", test
  end
  after :all do
    backtrace
  end
end
