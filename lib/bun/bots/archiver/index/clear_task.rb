#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "clear", "Clear file index for archive"
option 'at', :aliases=>'-a', :type=>'string', :desc=>'Archive location'
def clear
  archive = Archive.new(:at=>options[:at])
  archive.clear_index
end