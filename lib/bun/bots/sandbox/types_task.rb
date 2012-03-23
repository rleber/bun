#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "types", "List file types"
option 'archive', :aliases=>'-a', :type=>'string',  :desc=>'Archive location'
option "build",   :aliases=>"-b", :type=>'boolean', :desc=>"Don't rely on archive index; always build information from source file"
def types
  archive = Archive.new(:location=>options[:archive])
  archive.each do |tape_name|
    file = archive.descriptor(tape_name, :build=>options[:build])
    puts "#{tape_name}: #{file[:file_type]}"
  end
end