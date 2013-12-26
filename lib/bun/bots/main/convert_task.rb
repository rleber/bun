#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "convert ARCHIVE FILE [TO]", "Read in a raw Bun file and translate to a flat YAML format"
def convert(at, file, to=nil)
  archive = Archive.new(at)
  archive.convert_single(file, to)
end