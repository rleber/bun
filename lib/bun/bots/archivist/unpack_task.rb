#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "unpack ARCHIVE TO", "Convert all the files in the archive from Bun binary format to YAML digest"
option 'dryrun',  :aliases=>'-d', :type=>'boolean', :desc=>"Perform a dry run. Do not actually unpack"
option 'flatten', :aliases=>'-f', :type=>'boolean', :desc=>"Flatten out intermediate /ar99 directories"
option 'quiet',   :aliases=>'-q', :type=>'boolean', :desc=>'Run quietly'
option 'strict',  :aliases=>'-s', :type=>'boolean', :desc=>"Only unpack files of the form ar999.9999"
def unpack(at, to)
  check_for_unknown_options(at, to)
  Archive.unpack(at, to, options)
end