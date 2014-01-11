#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "bake FILE [TO]", "Output the ASCII content for the files"
option 'asis',  :aliases=>'-a', :type=>'boolean', :desc=>"Do not attempt to decode file first"
option "tape", :aliases=>'-t', :type=>'string',  :desc=>"Supply tape name (use with input from STDIN)"
def bake(from, to='-')
  check_for_unknown_options(from, to)
  File::Decoded.bake(from, to, options.merge(promote: !options[:asis]))
end