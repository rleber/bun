#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "bake ARCHIVE TO", "Output the ASCII content for all the files in the archive"
option 'dryrun',  :aliases=>'-d', :type=>'boolean', :desc=>"Perform a dry run. Do not actually put"
option 'now',     :aliases=>'-n', :type=>'boolean', :desc=>'Create files with current timestamp'
option 'quiet',   :aliases=>'-q', :type=>'boolean', :desc=>'Run quietly'
def bake(at, to)
  check_for_unknown_options(at, to)
  Library.new(at).bake(to, options)
end