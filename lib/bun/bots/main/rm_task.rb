#!/usr/bin/env rvm-ruby 1.9.3
# -*- encoding: us-ascii -*-

desc "rm TAPE [TAPE...]", "Remove files from archive"
option 'archive', :aliases=>'-a', :type=>'string',  :desc=>'Archive location'
def rm(*args)
  from_archive = Archive.new(:location=>options[:archive])
  from_archive.rm(:tapes=>args)
end