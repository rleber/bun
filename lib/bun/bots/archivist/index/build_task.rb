#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "build", "Build file index for archive"
option 'at',        :aliases=>'-a', :type=>'string',  :desc=>'Archive location'
option 'quiet',     :aliases=>'-q', :type=>'boolean', :desc=>'Run quietly'
option 'recursive', :aliases=>'-r', :type=>'boolean', :desc=>'Recursively build indexes in sub-directories'
def build
  archive = Archive.new(:at=>options[:at])
  archive.build_and_save_index(:verbose=>!options[:quiet], :recursive=>options[:recursive])
end