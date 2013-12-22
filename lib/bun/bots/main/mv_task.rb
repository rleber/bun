#!/usr/bin/env rvm-ruby 1.9.3
# -*- encoding: us-ascii -*-

desc "mv ARCHIVE FROM  TO", "Move files in/from archive"
option 'bare',    :aliases=>'-b', :type=>'boolean', :desc=>'Move files, but not index data'
def mv(at, from, to)
  from_archive = Archive.new(at)
  from_archive.mv(:from=>from, :to=>to, :bare=>options[:bare])
end