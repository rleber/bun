#!/usr/bin/env rvm-ruby 1.9.3
# -*- encoding: us-ascii -*-

desc "mv FROM  TO", "Move files in/from archive"
option 'archive', :aliases=>'-a', :type=>'string',  :desc=>'Archive location'
option 'bare',    :aliases=>'-b', :type=>'boolean', :desc=>'Move files, but not index data'
def mv(from, to)
  from_archive = Archive.new(:at=>options[:archive])
  from_archive.mv(:from=>from, :to=>to, :bare=>options[:bare])
end