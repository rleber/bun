#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "compact LIBRARY [TO]", "Remove redundant files from library"
option "quiet", :aliases=>'-q', :type=>'boolean', :desc=>'Quiet mode'
def compact(from, to=nil)
  check_for_unknown_options(from, to)
  if to
    target = to
    Shell.new(:quiet=>options[:quiet]).cp_r(from, to)
  else
    target = from
  end
  # Library.new(target).compact!
end