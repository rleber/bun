#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "dump ARCHIVE FILE SHARD", "Dump a frozen Honeywell file"
option 'at',      :aliases=>'-a', :type=>'string',  :desc=>'Archive path'
option "escape",  :aliases=>'-e', :type=>'boolean', :desc=>'Display unprintable characters as hex digits'
option "lines",   :aliases=>'-l', :type=>'numeric', :desc=>'How many lines of the dump to show'
option "offset",  :aliases=>'-o', :type=>'numeric', :desc=>'Skip the first n lines'
option "spaces",  :aliases=>'-s', :type=>'boolean', :desc=>'Display spaces unchanged'
option "thawed",  :aliases=>'-t', :type=>'boolean', :desc=>'Display the file in partially thawed format'
def dump(at, file_name, n)
  limit = options[:lines]
  archive = Archive.new(at)
  directory = archive.at
  file = archive.open(file_name)
  stop "!File #{file_name} is an archive of #{archived_file}, which is not frozen." unless file.file_type == :frozen
  archived_file = file.path
  archived_file = "--unknown--" unless archived_file
  file_index = file.shard_index(n)
  shard_descriptor = file.shard_descriptors.at(file_index)
  puts "Archive at #{file.hoard_path}[#{shard_descriptor.name}] for #{shard_descriptor.path}:"
  if options[:thawed]
    p file
    lines = file.lines(file_index)
    # TODO Refactor using Array#justify_rows
    offset_width = ('%o'%lines[-1][:offset]).size
    lines.each do |l|
      offset = '0' + ("%0#{offset_width}o" % l[:offset])
      descriptor = l[:descriptor]
      top_bits = File::Frozen.top_descriptor_bits(descriptor)
      clipped_length = File::Frozen.clipped_line_length(descriptor)
      bottom_bits = File::Frozen.bottom_descriptor_bits(descriptor)
      flag = File::Frozen::good_descriptor?(descriptor) ? ' ' : '!'
      puts "#{offset} #{'%012o'%descriptor} " + 
           "#{'%03o'%top_bits}|#{'%03o'%clipped_length} #{flag} " +
           "#{l[:raw].inspect[1..-2]}"
    end
  else
    content = file.shard_words(file_index)
    Dump.dump(content, options.merge(:frozen=>true))
  end
end