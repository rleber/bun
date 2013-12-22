#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "types", "List file types"
option "build",   :aliases=>"-b", :type=>'boolean', :desc=>"Don't rely on at index; always build information from source file"
def types(at)
  archive = Archive.new(at)
  archive.each do |tape|
    file = archive.descriptor(tape, :build=>options[:build])
    puts "#{tape}: #{file[:file_type]}"
  end
end