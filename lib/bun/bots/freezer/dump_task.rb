#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# TODO lines, length, and offset options don't really work
desc "dump FILE SHARD", "Dump a frozen Honeywell file"
option "decoded", :aliases=>'-d', :type=>'boolean', :desc=>'Display the file in partially decoded format'
option "escape",  :aliases=>'-e', :type=>'boolean', :desc=>'Display unprintable characters as hex digits'
option "length",  :aliases=>'-L', :type=>'string',  :desc=>'Limit dump to this many words'
option "lines",   :aliases=>'-l', :type=>'numeric', :desc=>'How many lines of the dump to show'
option "offset",  :aliases=>'-o', :type=>'numeric', :desc=>'Skip the first n lines'
option "spaces",  :aliases=>'-s', :type=>'boolean', :desc=>'Display spaces unchanged'
def dump(file_name, n)
  check_for_unknown_options(file_name, n)
  begin
    offset = options[:offset] ? eval(options[:offset]) : 0   # So octal or hex values can be given
  rescue => e
    stop "!Bad value for --offset: #{e}"
  end
  begin
    lines_option  = options[:lines]  ? eval(options[:lines])  : nil # So octal or hex values can be given
  rescue => e
    stop "!Bad value for --lines: #{e}"
  end
  begin
    length = options[:length] ? eval(options[:length]) : nil # So octal or hex values can be given
  rescue => e
    stop "!Bad value for --length: #{e}"
  end
  File::Frozen.open(file_name, :graceful=>true) do |file|
    archived_file = file.path
    archived_file = "--unknown--" unless archived_file
    file_index = file.shard_index(n)
    shard_descriptor = file.shard_descriptors.at(file_index)
    path = File.join(file.descriptor.path, shard_descriptor.name)
    lines_option = options[:lines]
    puts "#{File.expand_path(file_name)}[#{shard_descriptor.name}] (#{path}):"
    puts_options "  Options: "
    if options[:decoded]
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
end