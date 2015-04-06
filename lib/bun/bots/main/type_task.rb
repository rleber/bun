#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Determine file format (e.g. packed, unpacked, decoded) for any file 

desc "type FILE", "Display the type of a file (e.g. frozen, huffman, etc.)"
def type(file)
  check_for_unknown_options(file)
  puts File.type(file)
end
