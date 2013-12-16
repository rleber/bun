#!/usr/bin/env rvm-ruby 1.9.3
# -*- encoding: us-ascii -*-

desc "mkdir PATH", "Make a directory in the archive"
option 'at',      :aliases=>'-a', :type=>'string',  :desc=>'Archive path'
option 'parents', :aliases=>'-p', :type=>'boolean', :desc=>'Construct all parent directories, if missing'
def mkdir(path)
  archive = Archive.new(:at=>options[:at])
  archive.mkdir(path, options)
end