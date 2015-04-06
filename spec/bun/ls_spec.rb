#!/usr/bin/env rvm-ruby 1.9.3
# -*- encoding: us-ascii -*-

describe "ls" do
  include_examples "command", 
                   "ls", 
                   "ls #{TEST_ARCHIVE}", 
                   "ls"
  include_examples "command", 
                   "ls -o", 
                   "ls -o #{TEST_ARCHIVE}", 
                   "ls_o"
  include_examples "command", 
                   "ls -ldr with normal file (ar003.0698)", 
                   "ls -ldr #{TEST_ARCHIVE}/ar003.0698.bun", 
                   "ls_ldr_ar003.0698"
  include_examples "command", 
                   "ls -ldr with frozen file (ar145.2699)", 
                   "ls -ldr #{TEST_ARCHIVE}/ar145.2699.bun", 
                   "ls_ldr_ar145.2699"
  include_examples "command", 
                   "ls with glob", 
                   "ls #{TEST_ARCHIVE}/ar08*", 
                   "ls_glob"
  after :all do
    backtrace
  end
end
