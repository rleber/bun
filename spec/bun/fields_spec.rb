#!/usr/bin/env rvm-ruby 1.9.3
# -*- encoding: us-ascii -*-

describe "fields" do
  [
    {
      :title=>"no options",
      :command=>"fields"
    },
    {
      :title=>"-l option",
      :command=>"fields -l"
    },
    {
      :title=>"with pattern",
      :command=>"fields time"
    },
    {
      :title=>"with pattern and -l",
      :command=>"fields time -l"
    },
  ].each do |test|
    exec_test_hash "fields", test
  end
end
