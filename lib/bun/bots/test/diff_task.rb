#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "diff ACTUAL [EXPECTED]", "Compare test output vs. expected"
def diff(actual='*',expected=nil)
  files = Dir.glob(File.join(Bun::Test::ACTUAL_OUTPUT_DIRECTORY,actual)) 
             .map{|f| f.sub(/^#{Bun::Test::ACTUAL_OUTPUT_DIRECTORY}\//,'') } 
             .reject{|f| f=~/^_/}
  stop "!Can't use multiple actual files with expected file" if expected  && files.size > 1
  files.each do |f|
    puts "Diff for #{f}:"
    Bun::Test.diff(f, expected)
  end
end