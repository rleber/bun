#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "compact LIBRARY [TO]", "Remove redundant files from library"
def compact(from, to=nil)
  if to
    target = to
    Library.new(from).cp(:from=>'*', :to=>to, :recursive=>true)
  else
    target = from
  end
  # Library.new(target).compact!
end