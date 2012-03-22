#!/usr/bin/env rvm-ruby 1.9.3
# -*- encoding: us-ascii -*-

desc "mv TAPE [TAPE...] [DESTINATION]", "Move files in/from archive"
option 'archive', :aliases=>'-a', :type=>'string',  :desc=>'Archive location'
option 'bare',    :aliases=>'-b', :type=>'boolean', :desc=>'Move files, but not index data'
def mv(*args)
  directory = options[:archive] || Archive.location
  from_archive = Archive.new(:location=>directory)
  if args.size == 1
    dest = nil
  else
    dest = args.pop
  end
  from_archive.mv(:from=>args, :to=>dest, :bare=>options[:bare])
end