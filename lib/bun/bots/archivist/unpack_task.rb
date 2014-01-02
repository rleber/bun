#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "unpack ARCHIVE TO", "Convert all the files in the archive from Bun binary format to YAML digest"
option 'dryrun',  :aliases=>'-d', :type=>'boolean', :desc=>"Perform a dry run. Do not actually unpack"
option 'quiet',   :aliases=>'-q', :type=>'boolean', :desc=>'Run quietly'
def unpack(at, to)
  Archive.unpack(at, to, options)
end