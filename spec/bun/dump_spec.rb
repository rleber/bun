#!/usr/bin/env rvm-ruby 1.9.3
# -*- encoding: us-ascii -*-

describe "dump" do
  include_examples "command", 
                   "dump ar003.0698", 
                   "dump #{TEST_ARCHIVE}/ar003.0698.bun", 
                   "dump_ar003.0698"
  include_examples "command", 
                   "dump -s ar003.0698", 
                   "dump -s #{TEST_ARCHIVE}/ar003.0698.bun",
                   "dump_s_ar003.0698"
  include_examples "command", 
                   "dump ar004.0888", 
                   "dump #{TEST_ARCHIVE}/ar004.0888.bun", 
                   "dump_ar004.0888"
  include_examples "command", 
                   "dump -f ar004.0888", 
                   "dump -f #{TEST_ARCHIVE}/ar004.0888.bun",
                   "dump_f_ar004.0888"
  include_examples "command from STDIN", 
                   "dump ar003.0698", 
                   "dump - ", 
                   "#{TEST_ARCHIVE}/ar003.0698.bun", 
                   "dump_stdin_ar003.0698"
  after :all do
    backtrace
  end
end
