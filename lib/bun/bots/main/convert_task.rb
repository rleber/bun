#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "convert FILE [TO]", "Read in a raw Bun file and translate to a flat YAML format"
def convert(file, to=nil)
  at = File.dirname(file)
  file = File.basename(file)
  # TODO Is the Archive object even necessary here?
  archive = Archive.new(at)
  archive.convert_single(file, to)
end