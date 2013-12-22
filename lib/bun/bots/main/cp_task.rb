#!/usr/bin/env rvm-ruby 1.9.3
# -*- encoding: us-ascii -*-

desc "cp ARCHIVE TAPE... [DESTINATION]", "Copy tapes from archive"
option 'bare',      :aliases=>'-b', :type=>'boolean', :desc=>'Copy tapes, but not index data'
option 'recursive', :aliases=>'-r', :type=>'boolean', :desc=>'Recursively copy sub-directories'
def cp(*args)
  if args.size <= 2
    dest = nil
  else
    dest = args.pop
  end
  from_archive = Archive.new(args.shift)
  from_archive.cp(:from=>args, :to=>dest, :bare=>options[:bare], :recursive=>options[:recursive])
end