#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "extract TO", "Extract all the files in the archive"
option 'at',      :aliases=>'-a', :type=>'string',  :desc=>'Archive location'
option 'dryrun',  :aliases=>'-d', :type=>'boolean', :desc=>"Perform a dry run. Do not actually extract"
option 'quiet',   :aliases=>'-q', :type=>'boolean', :desc=>'Run quietly'
def extract(to)
  Archive.new(:at=>options[:at]).extract(to, options)
end