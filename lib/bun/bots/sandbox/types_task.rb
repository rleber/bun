#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "types", "List file types"
option 'at',      :aliases=>'-a', :type=>'string',  :desc=>'Archive location'
option "build",   :aliases=>"-b", :type=>'boolean', :desc=>"Don't rely on at index; always build information from source file"
def types
  archive = Archive.new(:at=>options[:at])
  archive.each do |location|
    file = archive.descriptor(location, :build=>options[:build])
    puts "#{location}: #{file[:file_type]}"
  end
end