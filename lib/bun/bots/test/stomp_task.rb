#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "stomp FILE", "Permanently change the expected output in the indicated file"
option 'dryrun', :aliases=>'-d', :type=>'boolean', :desc=>"Don't actually run the command"
option 'last',   :aliases=>'-l', :type=>'boolean', :desc=>"Stomp the file with the last tested output"
option 'number', :aliases=>'-n', :type=>'string',  :default=>'-1', :desc=>"Use the indexed command (-1 == last) for --redo"
option 'quiet',  :aliases=>'-q', :type=>'boolean', :desc=>"Quiet mode"
option 'redo',   :aliases=>'-r', :type=>'boolean', :desc=>"Stomp the file by rerunning the command"
def stomp(file=nil)
  stop "!Bad value for --number: #{options[:number].inspect}" unless options[:number] =~ /^[+-]\d+$/
  n = options[:number].to_i
  trace = Bun::Test.backtrace(range: n)
  stop "!No backtrace available" if trace.size < 1
  if options[:last]
    stop "!Can't use --last and specify file name" if file
    actual_output_file = Bun::Test.last_actual_output_file
    expected_output_file = actual_output_file.sub(/^#{Regexp.escape(Bun::Test::ACTUAL_OUTPUT_DIRECTORY)}/,Bun::Test::EXPECTED_OUTPUT_DIRECTORY)
  else
    stop "!Must specify file name (or use --last" unless file
    actual_output_file = File.join(Bun::Test::ACTUAL_OUTPUT_DIRECTORY, file)
    expected_output_file = File.join(Bun::Test::EXPECTED_OUTPUT_DIRECTORY, file)
  end
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