#!/usr/bin/env rvm-ruby 1.9.3
# -*- encoding: us-ascii -*-

describe "freezer" do
  context "ls" do
    include_examples "command", 
                     "freezer ls ar004.0888", 
                     "freezer ls #{TEST_ARCHIVE}/ar004.0888.bun",
                     "freezer_ls_ar004.0888"
    include_examples "command", 
                     "freezer ls -l ar004.0888", 
                     "freezer ls -l #{TEST_ARCHIVE}/ar004.0888.bun", 
                     "freezer_ls_l_ar004.0888"
    include_examples "command from STDIN", 
                     "freezer ls ar004.0888", 
                     "freezer ls -",
                     "#{TEST_ARCHIVE}/ar004.0888.bun",
                     "freezer_ls_stdin_ar004.0888"
    after :all do
      backtrace
    end
  end
end
