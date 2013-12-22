#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "clear ARCHIVE", "Clear file index for archive"
option 'at', :aliases=>'-a', :type=>'string', :desc=>'Archive path'
def clear(at)
  archive = Archive.new(at)
  archive.clear_index
end