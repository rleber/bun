#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "convert ARCHIVE TO", "Convert all the files in the archive from Bun binary format to YAML digest"
option 'dryrun',  :aliases=>'-d', :type=>'boolean', :desc=>"Perform a dry run. Do not actually extract"
option 'quiet',   :aliases=>'-q', :type=>'boolean', :desc=>'Run quietly'
def convert(at, to)
  Archive.new(at).convert('**/*', to, options)
end