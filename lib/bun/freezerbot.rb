require 'bun/archive'
require 'bun/shell'

class Bun

  class FreezerBot < Thor
    
    # TODO Consider combining this with bot.rb

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
      abort "!Unknown --sort setting. Must be one of #{SORT_VALUES.join(', ')}" unless SORT_VALUES.include?(options[:sort])
      file_pattern = get_regexp(options[:files])
      abort "!Invalid --files pattern. Should be a valid Ruby regular expression (except for the delimiters)" unless file_pattern
      directory = options[:archive] || Archive.location
      archive = Archive.new(directory)
      file = archive.open(file_name)
      abort "!File #{file_name} is an archive of #{archived_file}, which is not frozen." unless file.file_type == :frozen
      archived_file = file.path
      archived_file = "--unknown--" unless archived_file
      print "Frozen archive for directory #{archived_file}"
      print "\nLast updated at #{file.update_time.strftime(TIMESTAMP_FORMAT)}" if options[:long]
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
        file_info << {'order'=>i, 'update'=>descr.update_time, 'size'=>descr.file_size, 'name'=>descr.name}
      end
      sorted_order = file_info.sort_by{|fi| [fi[options[:sort]], fi['name']]}.map{|fi| fi['order']} # Sort it in order
      # Accumulate the display
      sorted_order.each do |i|
        descr = file.shard_descriptor(i)
        if options[:long]
          update_time = descr.update_time
          lines << "#{'%5d'%(i)} #{'%-8s'%descr.name}  #{update_time.strftime(TIMESTAMP_FORMAT)}  #{'%10d'%descr.file_size}  #{'%#012o'% (descr.start + file.content_offset)}"
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

    desc "dump ARCHIVE FILE", "Uncompress a frozen Honeywell file"
    option 'archive', :aliases=>'-a', :type=>'string',  :desc=>'Archive location'
    option "escape",  :aliases=>'-e', :type=>'boolean', :desc=>'Display unprintable characters as hex digits'
    option "lines",   :aliases=>'-l', :type=>'numeric', :desc=>'How many lines of the dump to show'
    option "offset",  :aliases=>'-o', :type=>'numeric', :desc=>'Skip the first n lines'
    option "thawed",  :aliases=>'-t', :type=>'boolean', :desc=>'Display the file in partially thawed format'
    def dump(file_name, n)
      limit = options[:lines]
      directory = options[:archive] || Archive.location
      archive = Archive.new(directory)
      file = archive.open(file_name)
      abort "!File #{file_name} is an archive of #{archived_file}, which is not frozen." unless file.file_type == :frozen
      archived_file = file.path
      archived_file = "--unknown--" unless archived_file
      file_index = file.shard_index(n)
      puts "Archive for file_name #{file.shard_name(file_index)}:"
      if options[:thawed]
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

    # TODO Thaw all files
    desc "thaw ARCHIVE FILE [TO]", "Uncompress a frozen Honeywell file"
    option 'archive', :aliases=>'-a', :type=>'string',  :desc=>'Archive location'
    option "log",     :aliases=>'-l', :type=>'string',  :desc=>"Log status to specified file"
    option "strict",  :aliases=>"-s", :type=>"boolean", :desc=>"Check for bad data. Abort if found"
    option "warn",    :aliases=>"-w", :type=>"boolean", :desc=>"Warn if bad data is found"
    long_desc <<-EOT
FILE may have some special formats: '+-nnn' (where nnn is an integer) denotes file number nnn. '-nnn' denotes the nnnth
file from the end of the archive. Anything else denotes the name of a file. A backslash character is ignored at the
beginning of a file name, so that '\\+1' refers to a file named '+1', whereas '+1' refers to the first file in the archive,
whatever its name.
    EOT
    def thaw(file_name, n, out=nil)
      directory = options[:archive] || Archive.location
      archive = Archive.new(directory)
      file = archive.open(file_name)
      abort "!File #{file_name} is an archive of #{archived_file}, which is not frozen." unless file.file_type == :frozen
      archived_file = file.path
      archived_file = "--unknown--" unless archived_file
      content = file.shard(file.shard_index(n))
      shell = Shell.new
      shell.write out, content, :timestamp=>file.update_time, :quiet=>true
      warn "Thawed with #{file.errors} decoding errors" if options[:warn] && file.errors > 0
      shell.log options[:log], "thaw #{out.inspect} from #{file_name.inspect} with #{file.errors} errors" if options[:log]
    end
  end
end
