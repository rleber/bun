#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "stomp FILE", "Permanently change the expected output in the indicated file"
option 'dryrun', :aliases=>'-d', :type=>'boolean', :desc=>"Don't actually run the command"
option 'number', :aliases=>'-n', :type=>'string',  :default=>'-1', :desc=>"Use the indexed command (-1 == last) for --redo"
option 'quiet',  :aliases=>'-q', :type=>'boolean', :desc=>"Quiet mode"
option 'redo',   :aliases=>'-r', :type=>'boolean', :desc=>"Stomp the file by rerunning the command"
def stomp(file)
  stop "!Bad value for --number: #{options[:number].inspect}" unless options[:number] =~ /^[+-]\d+$/
  n = options[:number].to_i
  trace = Bun::Test.backtrace(range: n)
  stop "!No backtrace available" if trace.size < 1
  actual_output_file = File.join(Bun::Test::ACTUAL_OUTPUT_DIRECTORY, file)
  expected_output_file = File.join(Bun::Test::EXPECTED_OUTPUT_DIRECTORY, file)
  if options[:redo]
    command = trace[options[:number].to_i]
    pat = /#{Regexp.escape(actual_output_file)}/
    stop "!Can't find #{actual_output_file} in command (from trace): #{command}" unless command =~ pat
    command = command.gsub(pat, expected_output_file)
  else
    command = "cp -rf #{actual_output_file} #{expected_output_file}"
  end
  puts command unless options[:quiet]
  system(command) unless options[:dryrun]
end