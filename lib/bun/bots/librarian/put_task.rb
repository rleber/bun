#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "put ARCHIVE TO", "Output the content for all the files in the archive"
option 'dryrun',  :aliases=>'-d', :type=>'boolean', :desc=>"Perform a dry run. Do not actually put"
option 'quiet',   :aliases=>'-q', :type=>'boolean', :desc=>'Run quietly'
def put(at, to)
  Library.new(at).put(to, options)
end