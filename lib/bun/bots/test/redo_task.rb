#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "redo [N]", "Rerun the Nth command in the backtrace (-1 is default: last command)"
option 'dryrun', :aliases=>'-d', :type=>'boolean', :desc=>"Don't actually run the command"
option 'quiet',  :aliases=>'-q', :type=>'boolean', :desc=>"Quiet mode"
def redo(n=-1)
  n = n.to_i
  trace = Bun::Test.backtrace(range: n)
  command = trace[n.to_i]
  stop "!Command number out of range" unless command
  puts command unless options[:quiet]
  system(command) unless options[:dryrun]
end