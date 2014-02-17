#!/usr/bin/env rvm-ruby 1.9.3
# -*- encoding: us-ascii -*-

describe "traits" do
  [
    {
      :title=>"no options",
      :command=>"traits"
    },
    {
      :title=>"-l option",
      :command=>"traits -l"
    },
    {
      :title=>"-o option",
      :command=>"traits -o"
    },
    {
      :title=>"with pattern",
      :command=>"traits c"
    },
    {
      :title=>"with pattern and -o",
      :command=>"traits c -o"
    },
  ].each do |test|
    exec_test_hash "traits", test
  end
end
