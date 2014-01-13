#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

TIMESTAMP_FORMAT = "%m/%d/%Y %H:%M:%S"

no_tasks do
  def get_regexp(pattern)
    Regexp.new(pattern)
  rescue
    nil
  end
end

DEFAULT_WIDTH = 120 # TODO Read the window size for this
SORT_VALUES = %w{order name size update}
desc "ls FILE", "List contents of a frozen Honeywell file"
option "shard",   :aliases=>"-s", :type=>'string',  :default=>'.*',              :desc=>"Show only files that match this Ruby Regexp, e.g. 'f.*oo\\.rb$'"
option "long",    :aliases=>'-l', :type=>'boolean',                              :desc=>"Display listing in long format"
option "one",     :aliases=>'-1', :type=>'boolean',                              :desc=>"Display one file per line (implied by --long)"
option "sort",    :aliases=>"-S", :type=>'string',  :default=>SORT_VALUES.first, :desc=>"Sort order for files (#{SORT_VALUES.join(', ')})"
option "width",   :aliases=>'-w', :type=>'numeric', :default=>DEFAULT_WIDTH,     :desc=>"Width of display (for short format only)"
def ls(file_name)
  check_for_unknown_options(file_name)
  stop "!Unknown --sort setting. Must be one of #{SORT_VALUES.join(', ')}" unless SORT_VALUES.include?(options[:sort])
  shard_pattern = get_regexp(options[:shard])
  stop "!Invalid --shards pattern. Should be a valid Ruby regular expression (except for the delimiters)" unless shard_pattern
  File::Frozen.open(file_name, :graceful=>true) do |file|
    archived_file = file.path
    archived_file = "--unknown--" unless archived_file
    print "Frozen archive at #{File.expand_path(file_name)} for directory #{archived_file}"
    print "\nLast updated at #{file.file_time.strftime(TIMESTAMP_FORMAT)}" if options[:long]
    puts ":"
    lines = []
    # TODO Refactor using Array#justify_rows
    if options[:long]
      lines << "Index Shard     Updated                   Words         Start"
    end
    # Retrieve file information
    file_info = []
    file.shard_count.times do |i|
      descr = file.shard_descriptor(i)
      next unless descr.name=~shard_pattern
      file_info << {'order'=>i, 'update'=>descr.file_time, 'size'=>descr.tape_size, 'name'=>descr.name}
    end
    sorted_order = file_info.sort_by{|fi| [fi[options[:sort]], fi['name']]}.map{|fi| fi['order']} # Sort it in order
    # Accumulate the display
    sorted_order.each do |i|
      descr = file.shard_descriptor(i)
      if options[:long]
        file_time = descr.file_time
        line = []
        line << '%5d' % i
        line << '%-8s'%descr.name
        line << file_time.strftime(TIMESTAMP_FORMAT)
        line << '%10d'%descr[:size]
        line << '%#012o'% (descr.start + file.content_offset)
        lines << line.join('  ')
      else
        lines << descr.name
      end
    end
    if options[:long] || options[:one] # One file_name per line
      puts lines.join("\n")
    else # Multiple files per line
      file_width = (lines.map{|l| l.size}.max)+1
      files_per_line = [1, options[:width].div(file_width)].max
      index = 0
      while index < lines.size
        files_per_line.times do |i|
          break if index >= lines.size
          print "%-#{file_width}s"%lines[index]
          index += 1
        end
        puts
      end
    end
  end
end