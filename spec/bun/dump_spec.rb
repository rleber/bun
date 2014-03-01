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
  include_examples "command", 
                   "dump -S ar003.0704 (normal)", 
                   "dump -S #{TEST_ARCHIVE}/ar003.0704.bun", 
                   "dump_S_ar003.0704"
  include_examples "command", 
                   "dump -S ar019.0175 (frozen)", 
                   "dump -S #{TEST_ARCHIVE}/ar019.0175.bun", 
                   "dump_S_ar019.0175"
  include_examples "command", 
                   "dump -S ar047.1383 (BCD/binary normal)", 
                   "dump -S #{TEST_ARCHIVE}/ar047.1383.bun", 
                   "dump_S_ar047.1383"
  include_examples "command", 
                   "dump -S ar003.0701 (huffman)", 
                   "dump -S #{TEST_ARCHIVE}/ar003.0701.bun", 
                   "dump_S_ar003.0701"
  include_examples "command", 
                   "dump -S ar010.1307 (executable)", 
                   "dump -S #{TEST_ARCHIVE}/ar010.1307.bun", 
                   "dump_S_ar010.1307"
  after :all do
    backtrace
  end
end
