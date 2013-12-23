#!/usr/bin/env rvm-ruby 1.9.3
# -*- encoding: us-ascii -*-

desc "mkdir ARCHIVE PATH", "Make a directory in the archive"
option 'parents', :aliases=>'-p', :type=>'boolean', :desc=>'Construct all parent directories, if missing'
def mkdir(at, path)
  archive = Archive.new(at)
  archive.mkdir(path, options)
end