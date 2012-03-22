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
desc "ls ARCHIVE", "List contents of a frozen Honeywell file"
option 'archive', :aliases=>'-a', :type=>'string',                               :desc=>'Archive location'
option "descr",   :aliases=>'-d', :type=>'boolean',                              :desc=>"Display the file descriptor for each file (in octal)"
option "files",   :aliases=>"-f", :type=>'string',  :default=>'.*',              :desc=>"Show only files that match this Ruby Regexp, e.g. 'f.*oo\\.rb$'"
option "long",    :aliases=>'-l', :type=>'boolean',                              :desc=>"Display listing in long format"
option "one",     :aliases=>'-1', :type=>'boolean',                              :desc=>"Display one file per line (implied by --long or --descr)"
option "sort",    :aliases=>"-s", :type=>'string',  :default=>SORT_VALUES.first, :desc=>"Sort order for files (#{SORT_VALUES.join(', ')})"
option "width",   :aliases=>'-w', :type=>'numeric', :default=>DEFAULT_WIDTH,     :desc=>"Width of display (for short format only)"
def ls(file_name)
  stop "!Unknown --sort setting. Must be one of #{SORT_VALUES.join(', ')}" unless SORT_VALUES.include?(options[:sort])
  file_pattern = get_regexp(options[:files])
  stop "!Invalid --files pattern. Should be a valid Ruby regular expression (except for the delimiters)" unless file_pattern
  archive = Archive.new(:location=>options[:archive])
  directory = archive.location
  file = archive.open(file_name)
  stop "!File #{file_name} is an archive of #{archived_file}, which is not frozen." unless file.file_type == :frozen
  archived_file = file.path
  archived_file = "--unknown--" unless archived_file
  print "Frozen archive for directory #{archived_file}"
  print "\nLast updated at #{file.file_time.strftime(TIMESTAMP_FORMAT)}" if options[:long]
  puts ":"
  lines = []
  if options[:long]
    lines << "Index File      Updated                   Words         Start"
  elsif options[:descr]
    lines << "Index File     Descriptor"
  end
  # Retrieve file information
  file_info = []
  file.shard_count.times do |i|
    descr = file.shard_descriptor(i)
    next unless descr.name=~file_pattern
    file_info << {'order'=>i, 'update'=>descr.file_time, 'size'=>descr.file_size, 'name'=>descr.name}
  end
  sorted_order = file_info.sort_by{|fi| [fi[options[:sort]], fi['name']]}.map{|fi| fi['order']} # Sort it in order
  # Accumulate the display
  sorted_order.each do |i|
    descr = file.shard_descriptor(i)
    if options[:long]
      file_time = descr.file_time
      lines << "#{'%5d'%(i)} #{'%-8s'%descr.name}  #{file_time.strftime(TIMESTAMP_FORMAT)}  #{'%10d'%descr.file_size}  #{'%#012o'% (descr.start + file.content_offset)}"
    elsif options[:descr]
      lines << "#{'%5d'%(i)} #{'%-8s'%descr.name} #{descr.octal}"
    else
      lines << descr.name
    end
  end
  if options[:long] || options[:descr] || options[:one] # One file_name per line
    puts lines.join("\n")
  else # Multiple files per line
    # TODO Refactor using Array#justify_rows
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