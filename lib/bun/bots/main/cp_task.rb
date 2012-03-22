#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# TODO Copy more than one file
# TODO Copy by pattern
# TODO Create mv command

desc "cp TAPE [DESTINATION]", "Copy a file"
option 'archive', :aliases=>'-a', :type=>'string',  :desc=>'Archive location'
option 'bare',    :aliases=>'-b', :type=>'boolean', :desc=>'Copy file, but not index data'
def cp(tape, dest = nil)
  directory = options[:archive] || Archive.location
  from_archive = Archive.new(:location=>directory)
  from_archive.cp(tape, dest, options)
end