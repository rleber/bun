#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "build", "Build file index for archive"
option 'archive', :aliases=>'-a', :type=>'string',  :desc=>'Archive location'
option 'quiet',   :aliases=>'-q', :type=>'boolean', :desc=>'Run quietly'
def build
  archive = Archive.new(:location=>options[:archive])
  archive.build_and_save_index(:verbose=>!options[:quiet])
end