#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "stomp FILE", "Permanently change the expected output in the indicated file"
option 'dryrun', :aliases=>'-d', :type=>'boolean', :desc=>"Don't actually run the command"
option 'quiet',  :aliases=>'-q', :type=>'boolean', :desc=>"Quiet mode"
def stomp(file)
  trace = Bun::Test.backtrace(n: 1)
  stop "!No backtrace available" if trace.size < 1
  command = trace.first
  actual_output_file = File.join(Bun::Test::ACTUAL_OUTPUT_DIRECTORY, file)
  expected_output_file = File.join(Bun::Test::EXPECTED_OUTPUT_DIRECTORY, file)
  pat = /#{Regexp.escape(actual_output_file)}/
  stop "!Can't find #{actual_output_file} in command: #{command}" unless command =~ pat
  new_command = command.gsub(pat, expected_output_file)
  puts new_command unless options[:quiet]
  system(new_command) unless options[:dryrun]
end