#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "trace [RANGE]", "Output the last N commands executed during a test"
option 'indent',   :aliases=>'-i', :type=>'numeric', :default=>0, :desc=>"Indent commands"
option 'number',   :aliases=>'-n', :type=>'boolean', :default=>true, :desc=>"Number the lines"
option 'preserve', :aliases=>'-p', :type=>'boolean', :desc=>"Don't compress traced commands"
def trace(range='all')
  r = Bun::Test.trace_range(range)
  stop "!Bad range: #{range}" unless r
  trace = Bun::Test.backtrace(preserve: options[:preserve], range: r)
  number_width = trace.size.to_s.size
  number_width += 1 if r.end < 0
  number_format = "%#{number_width}s"
  trace.each.with_index do |c, i|
    i -= trace.size if r.end < 0
    c = "#{number_format % i} #{c}" if options[:number]
    c = (' '*options[:indent]) + c
    puts c
  end
end