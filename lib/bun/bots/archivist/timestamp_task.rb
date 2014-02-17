#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "timestamp ARCHIVE", "Set timestamps for all files in the archive"
option "quiet",    :aliases=>'-q', :type=>'boolean',  :desc=>"Don't announce each step of the process"
def timestamp(at)
  check_for_unknown_options(at)
  Archive.new(at).set_timestamps(:quiet=>options[:quiet])
end