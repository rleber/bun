#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "unpack FILE [TO]", "Read in a packed Bun file and translate to a flat YAML format"
option "tape", :aliases=>'-t', :type=>'string',  :desc=>"Supply tape name (use with input from STDIN)"
def unpack(file, to='-')
  File.unpack(file, to, options)
end