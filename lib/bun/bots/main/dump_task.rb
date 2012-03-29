#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "dump LOCATION", "Dump a Honeywell file"
option 'archive',   :aliases=>'-a', :type=>'string',  :desc=>'Archive location'
option "escape",    :aliases=>'-e', :type=>'boolean', :desc=>'Display unprintable characters as hex digits'
option "frozen",    :aliases=>'-f', :type=>'boolean', :desc=>'Display characters in frozen format (i.e. 5 per word)'
option "lines",     :aliases=>'-l', :type=>'numeric', :desc=>'How many lines of the dump to show'
option "offset",    :aliases=>'-o', :type=>'string',  :desc=>'Start at word n (zero-based index; octal/hex values allowed)'
option "unlimited", :aliases=>'-u', :type=>'boolean', :desc=>'Ignore the file size limit'
# TODO Deblock option
def dump(file_name)
  archive = Archive.new(options)
  begin
    offset = options[:offset] ? eval(options[:offset]) : 0 # So octal or hex values can be given
  rescue => e
    stop "!Bad value for --offset: #{e}"
  end
  file_path = archive.expand_path(file_name)
  file = Bun::File::Text.open(file_path)
  archived_file = file.path
  archived_file = "--unknown--" unless archived_file
  puts "Archive at #{file.location_path} for file #{archived_file}:"
  words = file.words
  lc = Dump.dump(words, options.merge(:offset=>offset))
  puts "No data to dump" if lc == 0
end