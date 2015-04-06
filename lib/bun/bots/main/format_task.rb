#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Determine file format (e.g. packed, unpacked, decoded) for any file 

desc "format FILE", "Determine the file format (e.g. packed, unpacked, etc.) for a file"
def format(file)
  check_for_unknown_options(file)
  puts File.format(file)
end
