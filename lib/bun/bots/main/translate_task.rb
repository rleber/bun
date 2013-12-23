#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "translate ARCHIVE FILE [TO]", "Read in a raw Bun file and translate to a flat YAML format"
def translate(at, file, to=nil)
  archive = Archive.new(at)
  archive.translate(file, to)
end