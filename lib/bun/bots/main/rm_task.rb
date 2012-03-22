#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "rm TAPE [TAPE...]", "Remove files from archive"
option 'archive', :aliases=>'-a', :type=>'string',  :desc=>'Archive location'
def rm(*args)
  directory = options[:archive] || Archive.location
  from_archive = Archive.new(:location=>directory)
  from_archive.rm(:tapes=>args)
end