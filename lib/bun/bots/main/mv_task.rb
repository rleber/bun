#!/usr/bin/env rvm-ruby 1.9.3
# -*- encoding: us-ascii -*-

desc "mv FROM  TO", "Move files in/from archive"
option 'at',      :aliases=>'-a', :type=>'string',  :desc=>'Archive path'
option 'bare',    :aliases=>'-b', :type=>'boolean', :desc=>'Move files, but not index data'
def mv(from, to)
  from_archive = Library.new(:at=>options[:at])
  from_archive.mv(:from=>from, :to=>to, :bare=>options[:bare])
end