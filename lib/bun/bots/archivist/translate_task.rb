#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "extract ARCHIVE TO", "Extract all the files in the archive"
option 'dryrun',  :aliases=>'-d', :type=>'boolean', :desc=>"Perform a dry run. Do not actually extract"
option 'quiet',   :aliases=>'-q', :type=>'boolean', :desc=>'Run quietly'
def extract(at, to)
  Archive.new(at).extract(to, options)
end