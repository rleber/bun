require 'gecos/archive'
require 'rleber-interaction'

class GECOS

  class FreezerBot < Thor
    include Interaction

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
      file = archive.qualified_tape_file_name(file)
      archived_file = archive.file_path(file)
      archived_file = "--unknown--" unless archived_file
      abort "File #{file} is an archive of #{archived_file}, which is not frozen." unless Archive.frozen?(file)
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
    
    no_tasks do
      def index_for(defroster, n)
        if n.to_s !~ /^-?\d+$/
          name = n
          n = defroster.file_index(name)
          abort "Frozen file does not contain a file #{name}" unless n
        else
          orig_n = n
          n = n.to_i
          n += defroster.files+1 if n<0
          abort "Frozen file does not contain file number #{orig_n}" if n<1 || n>defroster.files
          n -= 1
        end
        n
      end
    end
    
    no_tasks do
      def defrost(content)
        GECOS::Defroster.defrost(content)
      end
    end

    desc "thaw ARCHIVE FILE", "Uncompress a frozen Honeywell file"
    option "repair", :aliases=>"-r", :type=>"boolean", :desc=>"Attempt to repair damage in the file"
    option "strict", :aliases=>"-s", :type=>"boolean", :desc=>"Check for bad data. Abort if found"
    option "trace", :aliases=>"-t", :type=>"boolean", :desc=>"Print debugging trace information"
    option "warn", :aliases=>"-w", :type=>"boolean", :desc=>"Warn if bad data is found"
    def thaw(file, n)
      archive = Archive.new
      file = archive.qualified_tape_file_name(file)
      archived_file = archive.file_path(file)
      archived_file = "--unknown--" unless archived_file
      abort "File #{file} is an archive of #{archived_file}, which is not frozen." unless Archive.frozen?(file)
      decoder = GECOS::Decoder.new(File.read(file))
      defroster = GECOS::Defroster.new(decoder)
      GECOS::Defroster.options = options
      STDOUT.write defroster.content(index_for(defroster,n))
    end
    
    desc "recover ARCHIVE FILE TO_FILE", "Attempt to recover a frozen Honeywell file"
    def recover(file, n, to)
      archive = Archive.new
      file = archive.qualified_tape_file_name(file)
      archived_file = archive.file_path(file)
      archived_file = "--unknown--" unless archived_file
      abort "File #{file} is an archive of #{archived_file}, which is not frozen." unless Archive.frozen?(file)
      decoder = GECOS::Decoder.new(File.read(file))
      defroster = GECOS::Defroster.new(decoder)
      file_index = index_for(defroster, n)
      content = defroster.file_words(file_index)
      lines = nil
      loop do
        lines = defrost(content)
        flawed_line = lines.find {|l| l[:content].chomp =~ /[[:cntrl:]]/}
        break unless flawed_line
        offset = '0' + ('%o'%flawed_line[:offset])
        offset = '0' if offset == '00'
        flaw_location = Decoder.find_flaw(flawed_line[:content])
        STDERR.puts "Found a bad line at #{offset}: #{flawed_line[:content][0, flaw_location+5+1].inspect}"
        d1 = Decoder.new(nil)
        d1.words = content[flawed_line[:offset]..-1]
        remaining_characters = d1.frozen_characters
        search_start = flaw_location
        limit = nil
        start_location = nil
        end_location = nil
        next_line_end = nil
        from_text = nil
        to_text = nil
        loop do
          loop do
            if remaining_characters[(search_start+2)..-1] =~ /\r/m # +2 for the line length characters
              last_line_end = $`.size
              limit = (search_start + last_line_end + 1 + 19)/20 + 1 # Final +1 to show an extra line of context
            else
              abort "Unable to find a later line ending."
            end
            Dump.dump(content, :offset=>flawed_line[:offset], :lines=>limit, :frozen=>true)
            break unless get_logical("Need to see more? ", :prompt_on=>STDERR)
            search_start += last_line_end + 1
          end
          clipped_section = content[flawed_line[:offset], limit*4]
          d = Decoder.new(nil)
          d.words = clipped_section
          chars = d.frozen_characters
          start_location = nil
          loop do
            start_clip = Regexp.new(get_prompted("Clip from (regex) ", :prompt_on=>STDERR))
            start_location = chars =~ start_clip
            if start_location
              start_location += $&.length
              break
            end
            STDERR.puts "That does not match the text. Please try again."
          end
          end_location = nil
          loop do
            end_clip = Regexp.new(get_prompted("Clip to (regex) ", :prompt_on=>STDERR))
            end_location = chars =~ end_clip
            break if end_location
            STDERR.puts "That does not match the text. Please try again."
          end
          next_line_end = remaining_characters[end_location..-1] =~ /\r/m 
          abort "Can't find the end of the clipped line" unless next_line_end
          next_line_end += end_location
          from_text = remaining_characters[2..next_line_end]
          to_text = remaining_characters[2...start_location] + remaining_characters[end_location, next_line_end+1 - end_location]
          STDERR.puts "Line after clipping:  #{to_text.inspect}"
          break if get_logical("Is this correct? ", :prompt_on=>STDERR)
        end
        before_words = ((2+from_text.size)+4)/5
        after_words = ((2+to_text.size)+4)/5
        packed_line = [to_text.size]
        chs = 2
        to_text.unpack('C*').each do |c|
          if chs >= 5
            packed_line << 0
            chs = 0
          end
          packed_line[-1] = (packed_line[-1]<<7) + (c & 0x7f)
          chs += 1
        end
        content[flawed_line[:offset], before_words] = packed_line
      end
      File.open(to,'w') {|f| f.write lines.map{|l| l[:content]}.join}
    end

    option "lines", :aliases=>'-l', :type=>'numeric', :desc=>'How many lines of the dump to show'
    option "offset", :aliases=>'-o', :type=>'numeric', :desc=>'Skip the first n lines'
    option "escape", :aliases=>'-e', :type=>'boolean', :desc=>'Display unprintable characters as hex digits'
    option "thawed", :aliases=>'-t', :type=>'boolean', :desc=>'Display the file in partially thawed format'
    desc "dump ARCHIVE FILE", "Uncompress a frozen Honeywell file"
    def dump(file, n)
      limit = options[:lines]
      archive = Archive.new
      file = archive.qualified_tape_file_name(file)
      archived_file = archive.file_path(file)
      archived_file = "--unknown--" unless archived_file
      abort "File #{file} is an archive of #{archived_file}, which is not frozen." unless Archive.frozen?(file)
      decoder = GECOS::Decoder.new(File.read(file))
      defroster = GECOS::Defroster.new(decoder)
      defroster.options = {:warn=>true}
      file_index = index_for(defroster, n)
      puts "Archive for file #{defroster.file_name(file_index)}:"
      if options[:thawed]
        lines = defroster.lines(file_index)
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
    
    # TODO Is this useful? I suspect not. If not, remove it
    desc 'preamble ARCHIVE', "Show the preamble (the stuff that precedes any file)"
    def preamble(file)
      archive = Archive.new
      file = archive.qualified_tape_file_name(file)
      archived_file = archive.file_path(file)
      archived_file = "--unknown--" unless archived_file
      abort "File #{file} is an archive of #{archived_file}, which is not frozen." unless Archive.frozen?(file)
      decoder = GECOS::Decoder.new(File.read(file))
      defroster = GECOS::Defroster.new(decoder)
      puts "Preamble for archived file #{archived_file}:"
      preamble_content = decoder.words[0,defroster.offset]
      Dump.dump(preamble_content)
    end
  end
end
