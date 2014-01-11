#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "decode ARCHIVE TO", "Extract all the files in the archive"
option 'dryrun',  :aliases=>'-d', :type=>'boolean', :desc=>"Perform a dry run. Do not actually decode"
option 'quiet',   :aliases=>'-q', :type=>'boolean', :desc=>'Run quietly'
def decode(at, to)
  Archive.decode(at, to, options)
end