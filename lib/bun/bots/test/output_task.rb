#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "output [FILE]", "Echo test output"
option 'expected', :aliases=>'-e', :type=>'boolean', :desc=>"Show expected, rather than file file"
option 'last',     :aliases=>'-l', :type=>'boolean', :desc=>"Show the last tested output"
def output(file=nil)
  file = Bun::Test.last_actual_output_file if options[:last]
  stop "!Must specify file" unless file
  file = File.join(Bun::Test::ACTUAL_OUTPUT_DIRECTORY, file) unless file =~ /^(?:\/|#{Bun::Test::ACTUAL_OUTPUT_DIRECTORY})/
  file.sub!(/^#{Regexp.escape(Bun::Test::ACTUAL_OUTPUT_DIRECTORY)}/, Bun::Test::EXPECTED_OUTPUT_DIRECTORY) if options[:expected]
  stop "!File #{file} doesn't exist" unless File.exists?(file)
  puts File.read(file)
end