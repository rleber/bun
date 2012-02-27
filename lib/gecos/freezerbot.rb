require 'gecos/archive'
require 'gecos/shell'

class GECOS

  class FreezerBot < Thor

    TIMESTAMP_FORMAT = "%m/%d/%Y %H:%M:%S"

    no_tasks do
      def get_regexp(pattern)
        Regexp.new(pattern)
      rescue
        nil
      end
    end

    DEFAULT_WIDTH = 120
    SORT_VALUES = %w{order name size update}
    option "long", :aliases=>'-l', :type=>'boolean', :desc=>"Display listing in long format"
    option "one", :aliases=>'-1', :type=>'boolean', :desc=>"Display one file per line (implied by --long or --descr)"
    option "descr", :aliases=>'-d', :type=>'boolean', :desc=>"Display the file descriptor for each file (in octal)"
    option "width", :aliases=>'-w', :type=>'numeric', :default=>DEFAULT_WIDTH, :desc=>"Width of display (for short format only)"
    option "sort", :aliases=>"-s", :type=>'string', :default=>SORT_VALUES.first, :desc=>"Sort order for files (#{SORT_VALUES.join(', ')})"
    option "files", :aliases=>"-f", :type=>'string', :default=>'.*', :desc=>"Show only files that match this Ruby Regexp, e.g. 'f.*oo\\.rb$'"
    desc "ls ARCHIVE", "List contents of a frozen Honeywell file"
    def ls(file)
      abort "Unknown --sort setting. Must be one of #{SORT_VALUES.join(', ')}" unless SORT_VALUES.include?(options[:sort])
      file_pattern = get_regexp(options[:files])
      abort "Invalid --files pattern. Should be a valid Ruby regular expression (except for the delimiters)" unless file_pattern
      archive = Archive.new
      file = archive.expanded_tape_path(file)
      abort "File #{file} is an archive of #{archived_file}, which is not frozen." unless Archive.frozen?(file)
      archived_file = archive.file_path(file)
      archived_file = "--unknown--" unless archived_file
      decoder = GECOS::Decoder.new(File.read(file))
      defroster = GECOS::Defroster.new(decoder)
      print "Frozen archive for directory #{archived_file}"
      print "\nLast updated at #{defroster.update_time.strftime(TIMESTAMP_FORMAT)}" if options[:long]
      puts ":"
      lines = []
      if options[:long]
        lines << "Order File     Updated                   Words     Blocks     Offset"
      elsif options[:descr]
        lines << "Order File     Descriptor"
      end
      # Retrieve file information
      file_info = []
      defroster.files.times do |i|
        descr = defroster.descriptor(i)
        next unless descr.file_name=~file_pattern
        file_info << {'order'=>i, 'update'=>descr.update_time, 'size'=>descr.file_words, 'name'=>descr.file_name}
      end
      sorted_order = file_info.sort_by{|fi| [fi[options[:sort]], fi['name']]}.map{|fi| fi['order']} # Sort it in order
      # Accumulate the display
      sorted_order.each do |i|
        descr = defroster.descriptor(i)
        if options[:long]
          update_time = descr.update_time
          lines << "#{'%5d'%(i+1)} #{'%-8s'%descr.file_name} #{update_time.strftime(TIMESTAMP_FORMAT)} #{'%10d'%descr.file_words} #{'%10d'%descr.file_blocks} #{'%10d'%descr.file_start}"
        elsif options[:descr]
          lines << "#{'%5d'%(i+1)} #{'%-8s'%descr.file_name} #{descr.octal.scan(/.{12}/).join(' ')}"
        else
          lines << descr.file_name
        end
      end
      if options[:long] || options[:descr] || options[:one] # One file per line
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

    desc "thaw ARCHIVE FILE [TO]", "Uncompress a frozen Honeywell file"
    option "strict", :aliases=>"-s", :type=>"boolean", :desc=>"Check for bad data. Abort if found"
    option "warn", :aliases=>"-w", :type=>"boolean", :desc=>"Warn if bad data is found"
    option "log", :aliases=>'-l', :type=>'string', :desc=>"Log status to specified file"
    long_desc <<-EOT
FILE may have some special formats: '+-nnn' (where nnn is an integer) denotes file number nnn. '-nnn' denotes the nnnth
file from the end of the archive. Anything else denotes the name of a file. A backslash character is ignored at the
beginning of a file name, so that '\\+1' refers to a file named '+1', whereas '+1' refers to the first file in the archive,
whatever its name.
    EOT
    def thaw(file, n, out=nil)
      archive = Archive.new
      expanded_file = archive.expanded_tape_path(file)
      abort "File #{file} is an archive of #{archived_file}, which is not frozen." unless Archive.frozen?(expanded_file)
      archived_file = archive.file_path(expanded_file)
      archived_file = "--unknown--" unless archived_file
      decoder = GECOS::Decoder.new(File.read(expanded_file))
      defroster = GECOS::Defroster.new(decoder, :options=>options)
      content = defroster.content(defroster.fn(n))
      shell = Shell.new
      shell.write out, content, :timestamp=>defroster.update_time, :quiet=>true
      warn "Thawed with #{defroster.errors} decoding errors" if options[:warn] && defroster.errors > 0
      shell.log options[:log], "thaw #{out.inspect} from #{file.inspect} with #{defroster.errors} errors" if options[:log]
    end

    option "lines", :aliases=>'-l', :type=>'numeric', :desc=>'How many lines of the dump to show'
    option "offset", :aliases=>'-o', :type=>'numeric', :desc=>'Skip the first n lines'
    option "escape", :aliases=>'-e', :type=>'boolean', :desc=>'Display unprintable characters as hex digits'
    option "thawed", :aliases=>'-t', :type=>'boolean', :desc=>'Display the file in partially thawed format'
    desc "dump ARCHIVE FILE", "Uncompress a frozen Honeywell file"
    def dump(file, n)
      limit = options[:lines]
      archive = Archive.new
      file = archive.expanded_tape_path(file)
      archived_file = archive.file_path(file)
      archived_file = "--unknown--" unless archived_file
      abort "File #{file} is an archive of #{archived_file}, which is not frozen." unless Archive.frozen?(file)
      decoder = GECOS::Decoder.new(File.read(file))
      defroster = GECOS::Defroster.new(decoder, :warn=>true)
      file_index = defroster.fn(n)
      puts "Archive for file #{defroster.file_name(file_index)}:"
      if options[:thawed]
        lines = defroster.lines(file_index)
        # TODO Refactor using Array#justify_rows
        offset_width = ('%o'%lines[-1][:offset]).size
        lines.each do |l|
          offset = '0' + ("%0#{offset_width}o" % l[:offset])
          descriptor = l[:descriptor]
          top_bits = GECOS::Defroster.top_descriptor_bits(descriptor)
          clipped_length = GECOS::Defroster.clipped_line_length(descriptor)
          bottom_bits = GECOS::Defroster.bottom_descriptor_bits(descriptor)
          flag = GECOS::Defroster::good_descriptor?(descriptor) ? ' ' : '!'
          puts "#{offset} #{'%012o'%descriptor} " + 
               "#{'%03o'%top_bits}|#{'%03o'%clipped_length} #{flag} " +
               "#{l[:raw].inspect[1..-2]}"
        end
      else
        content = defroster.file_words(file_index)
        Dump.dump(content, options.merge(:frozen=>true))
      end
    end
  end
end
