#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "decode ARCHIVE TO", "Extract all the files in the archive"
option 'dryrun',  :aliases=>'-d', :type=>'boolean', :desc=>"Perform a dry run. Do not actually decode"
option "force",   :aliases=>'-f', :type=>'boolean', :desc=>"Overwrite existing files"
option 'scrub',   :aliases=>'-s', :type=>'boolean', :desc=>'Scrub control characters out of output'
option 'quiet',   :aliases=>'-q', :type=>'boolean', :desc=>'Run quietly'
def decode(at, to)
  check_for_unknown_options(at, to)
  Archive.decode(at, to, options)
end