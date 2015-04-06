#!/usr/bin/env rvm-ruby 1.9.3
# -*- encoding: us-ascii -*-

describe "freezer" do
  context "dump" do
    include_examples "command", 
                     "freezer dump ar004.0888 +0", 
                     "freezer dump #{TEST_ARCHIVE}/ar004.0888.bun +0", 
                     "freezer_dump_ar004.0888_0"
    include_examples "command", 
                     "freezer dump -s ar004.0888 +0", 
                     "freezer dump -s #{TEST_ARCHIVE}/ar004.0888.bun +0", 
                     "freezer_dump_s_ar004.0888_0"
    include_examples "command from STDIN", 
                     "freezer dump ar004.0888 +0", 
                     "freezer dump - +0",
                     "#{TEST_ARCHIVE}/ar004.0888.bun", 
                     "freezer_dump_stdin_ar004.0888_0"
    after :all do
      backtrace
    end
  end
end
