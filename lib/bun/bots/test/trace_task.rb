#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "trace [N]", "Output the last N commands executed during a test"
option 'indent',   :aliases=>'-i', :type=>'numeric', :default=>0, :desc=>"Indent commands"
option 'preserve', :aliases=>'-p', :type=>'boolean', :desc=>"Don't compress traced commands"
def trace(range=-1)
  trace = Bun::Test.backtrace(preserve: options[:preserve], range: range)
  puts trace.map{|c| (' '*options[:indent]) + c}
end