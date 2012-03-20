#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "build", "Build file index for archive"
option 'archive', :aliases=>'-a', :type=>'string',  :desc=>'Archive location'
option 'quiet',   :aliases=>'-q', :type=>'boolean', :desc=>'Run quietly'
def build
  # TODO the following two lines are a common pattern; refactor
  directory = options[:archive] || Archive.location
  archive = Archive.new(directory)
  archive.build_and_save_index(:verbose=>!options[:quiet])
end