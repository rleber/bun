#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "clear", "Clear file index for archive"
option 'archive', :aliases=>'-a', :type=>'string', :desc=>'Archive location'
def clear
  # TODO the following two lines are a common pattern; refactor
  directory = options[:archive] || Archive.location
  archive = Archive.new(:location=>directory)
  archive.clear_index
end