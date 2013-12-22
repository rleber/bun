#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "build ARCHIVE", "Build file index for archive"
option 'quiet',     :aliases=>'-q', :type=>'boolean', :desc=>'Run quietly'
option 'recursive', :aliases=>'-r', :type=>'boolean', :desc=>'Recursively build indexes in sub-directories'
def build(at)
  archive = Archive.new(at)
  archive.build_and_save_index(:verbose=>!options[:quiet], :recursive=>options[:recursive])
end