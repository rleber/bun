#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "dump FILE", "Dump the contents of a Honeywell backup tape"
option "escape",     :aliases=>'-e', :type=>'boolean', :desc=>'Display unprintable characters as hex digits'
option "frozen",     :aliases=>'-f', :type=>'boolean', :desc=>'Display characters in frozen format (i.e. 5 per word)'
option "length",     :aliases=>'-L', :type=>'string',  :desc=>'Limit dump to this many words'
option "lines",      :aliases=>'-l', :type=>'string',  :desc=>'How many lines of the dump to show'
option "offset",     :aliases=>'-o', :type=>'string',  :desc=>'Start at word n (zero-based index; octal/hex values allowed)'
option "spaces",     :aliases=>'-s', :type=>'boolean', :desc=>'Display spaces unchanged'
option "structured", :aliases=>'-S', :type=>'boolean', :desc=>'Use structured dump format'
# TODO Deblock option
def dump(file_name)
  check_for_unknown_options(file_name)
  begin
    offset = options[:offset] ? eval(options[:offset]) : 0   # So octal or hex values can be given
  rescue => e
    stop "!Bad value for --offset: #{e}"
  end
  begin
    lines  = options[:lines]  ? eval(options[:lines])  : nil # So octal or hex values can be given
  rescue => e
    stop "!Bad value for --lines: #{e}"
  end
  begin
    length = options[:length] ? eval(options[:length]) : nil # So octal or hex values can be given
  rescue => e
    stop "!Bad value for --length: #{e}"
  end
  opts = options.to_hash.inject({}) {|hsh, pair| key,value = pair; hsh[key.to_sym] = value; hsh}
  opts.merge!(offset: offset, length: length, lines: lines)
  force_type = case File.type(file_name)
  when :huffman
    :huffman
  when :huffword
    :huffword
  else
    :normal
  end
  Bun::File::Unpacked.open(file_name, :promote=>true, :force_type=>force_type, :fix=>true) do |file|
    archived_file = file.path
    archived_file = "--unknown--" unless archived_file
    path = File.expand_path(file_name)
    path += ", unpacked" unless path == File.expand_path(file.descriptor.tape_path)
    puts "#{path} (#{archived_file}):"
    puts_options "  Options: "
    lc = if options[:structured]
      Dump.structured_dump(file.data, opts)
    else
      Dump.dump(file.data, opts)
    end
    puts "No data to dump" if lc == 0
  end
end