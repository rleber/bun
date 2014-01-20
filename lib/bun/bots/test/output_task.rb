#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "output [ACTUAL]", "Echo test output"
option 'last',   :aliases=>'-l', :type=>'boolean', :desc=>"Show the last tested output"
def output(actual=nil)
  actual = Bun::Test.last_actual_output_file if options[:last]
  stop "!Must specify output file" unless actual
  actual = File.join(Bun::Test::ACTUAL_OUTPUT_DIRECTORY, actual) unless actual =~ /^(?:\/|#{Bun::Test::ACTUAL_OUTPUT_DIRECTORY})/
  stop "!File #{actual} doesn't exist" unless File.exists?(actual)
  puts File.read(actual)
end