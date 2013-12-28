#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "unpack FILE [TO]", "Read in a packed Bun file and translate to a flat YAML format"
def unpack(file, to=nil)
  File.unpack(file, to)
end