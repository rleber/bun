#!/usr/bin/env rvm-ruby 1.9.3
# -*- encoding: us-ascii -*-

describe "readme" do
  include_examples "command", "readme", "readme", "doc/readme.md"
  after :all do
    backtrace
  end
end
