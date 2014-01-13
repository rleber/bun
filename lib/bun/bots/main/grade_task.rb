#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Determine file grade (e.g. packed, unpacked, decoded) for any file 

desc "grade FILE", "Determine the file grade (e.g. packed, unpacked, etc.) for a file"
def grade(file)
  check_for_unknown_options(file)
  puts File.file_grade(file)
end
