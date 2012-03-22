#!/usr/bin/env rvm-ruby 1.9.3
# -*- encoding: us-ascii -*-

desc "cp TAPE [TAPE...] [DESTINATION]", "Copy files from archive"
option 'archive', :aliases=>'-a', :type=>'string',  :desc=>'Archive location'
option 'bare',    :aliases=>'-b', :type=>'boolean', :desc=>'Copy files, but not index data'
def cp(*args)
  from_archive = Archive.new(:location=>options[:archive])
  if args.size == 1
    dest = nil
  else
    dest = args.pop
  end
  from_archive.cp(:from=>args, :to=>dest, :bare=>options[:bare])
end