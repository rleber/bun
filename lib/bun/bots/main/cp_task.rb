#!/usr/bin/env rvm-ruby 1.9.3
# -*- encoding: us-ascii -*-

desc "cp LOCATION [LOCATION...] [DESTINATION]", "Copy files from archive"
option 'at',        :aliases=>'-a', :type=>'string',  :desc=>'Archive location'
option 'bare',      :aliases=>'-b', :type=>'boolean', :desc=>'Copy files, but not index data'
option 'recursive', :aliases=>'-r', :type=>'boolean', :desc=>'Recursively copy sub-directories'
def cp(*args)
  from_archive = Library.new(:at=>options[:at])
  if args.size == 1
    dest = nil
  else
    dest = args.pop
  end
  from_archive.cp(:from=>args, :to=>dest, :bare=>options[:bare], :recursive=>options[:recursive])
end