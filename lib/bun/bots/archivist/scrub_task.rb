#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "scrub ARCHIVE TO", "Remove control characters from all files in the archive"
option "ff",    :aliases=>'-f', :type=>'string',  :desc=>"Replace form feeds with this"
option 'quiet',   :aliases=>'-q', :type=>'boolean', :desc=>'Run quietly'
option "tabs",  :aliases=>'-t', :type=>'string',  :desc=>"Set tab stops"
option "vtab",  :aliases=>'-V', :type=>'string',  :desc=>"Replace vertical tabs with this"
option "width", :aliases=>'-w', :type=>'numeric', :desc=>"Column width"
def scrub(at, to)
  check_for_unknown_options(at, to)
  Library.new(at).scrub(to, options)
end