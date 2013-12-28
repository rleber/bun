#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "dump FILE SHARD", "Dump a frozen Honeywell file"
option "escape",  :aliases=>'-e', :type=>'boolean', :desc=>'Display unprintable characters as hex digits'
option "lines",   :aliases=>'-l', :type=>'numeric', :desc=>'How many lines of the dump to show'
option "offset",  :aliases=>'-o', :type=>'numeric', :desc=>'Skip the first n lines'
option "spaces",  :aliases=>'-s', :type=>'boolean', :desc=>'Display spaces unchanged'
option "thawed",  :aliases=>'-t', :type=>'boolean', :desc=>'Display the file in partially thawed format'
def dump(file, n)
  at = File.dirname(file)
  file_name = File.basename(file)
  # TODO Is the Archive object even necessary here?
  
  limit = options[:lines]
  archive = Archive.new(at)
  directory = archive.at
  file = archive.open(file_name)
  stop "!File #{file_name} is an archive of #{archived_file}, which is not frozen." unless file.file_type == :frozen
  archived_file = file.path
  archived_file = "--unknown--" unless archived_file
  file_index = file.shard_index(n)
  shard_descriptor = file.shard_descriptors.at(file_index)
  path = File.join(file.descriptor.path, shard_descriptor.name)
  puts "Archive at #{file.tape_path}[#{shard_descriptor.name}] for #{path}:"
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
    shard_start, shard_size = file.shard_extent(file_index)
    Dump.dump(file.data, options.merge(:frozen=>true, :offset=>shard_start, :limit=>shard_start + shard_size - 1))
  end
end