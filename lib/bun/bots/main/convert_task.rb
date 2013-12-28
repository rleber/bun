#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "convert FILE [TO]", "Read in a raw Bun file and translate to a flat YAML format"
def convert(file, to=nil)
  File.convert(file, to)
end