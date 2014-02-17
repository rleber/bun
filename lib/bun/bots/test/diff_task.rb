#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "diff ACTUAL [EXPECTED]", "Compare test output vs. expected"
option 'last',   :aliases=>'-l', :type=>'boolean', :desc=>"Do a diff on the last tested output"
def diff(actual='*',expected=nil)
  if options[:last]
    actual = Bun::Test.last_actual_output_file
    files = [actual]
  else
    files = Dir.glob(File.join(Bun::Test::ACTUAL_OUTPUT_DIRECTORY,actual), File::FNM_DOTMATCH) 
               .map{|f| f.sub(/^#{Bun::Test::ACTUAL_OUTPUT_DIRECTORY}\//,'') } 
               .reject{|f| f=~/^_/}
  end
  stop "!Can't use multiple actual files with expected file" if expected  && files.size > 1
  files.each do |f|
    puts "Diff for #{f}:"
    Bun::Test.diff(f, expected)
  end
end