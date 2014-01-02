#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "bake FILE [TO]", "Output the ASCII content for the files"
option "tape", :aliases=>'-t', :type=>'string',  :desc=>"Supply tape name (use with input from STDIN)"
def bake(from, to='-')
  File::Decoded.bake(from, to, options)
end