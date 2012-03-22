#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# TODO Create mv command

desc "cp TAPE [DESTINATION]", "Copy a file"
option 'archive', :aliases=>'-a', :type=>'string',  :desc=>'Archive location'
option 'bare',    :aliases=>'-b', :type=>'boolean', :desc=>'Copy file, but not index data'
def cp(*args)
  directory = options[:archive] || Archive.location
  from_archive = Archive.new(:location=>directory)
  if args.size == 1
    dest = nil
  else
    dest = args.pop
  end
  from_archive.cp(:from=>args, :to=>dest, :bare=>options[:bare])
end