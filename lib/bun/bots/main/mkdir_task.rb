#!/usr/bin/env rvm-ruby 1.9.3
# -*- encoding: us-ascii -*-

desc "mkdir PATH", "Make a directory in the archive"
option 'archive', :aliases=>'-a', :type=>'string',  :desc=>'Archive location'
option 'parents', :aliases=>'-p', :type=>'boolean', :desc=>'Construct all parent directories, if missing'
def mkdir(path)
  archive = Archive.new(:at=>options[:archive])
  archive.mkdir(path, options)
end