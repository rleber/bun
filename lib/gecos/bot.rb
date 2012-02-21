require 'thor'
require 'mechanize'
require 'fileutils'
require 'gecos/archive'
require 'gecos/decoder'
require 'gecos/defroster'
require 'gecos/archivebot'
require 'gecos/freezerbot'
require 'gecos/dump'
require 'rleber-interaction'

class GECOS
  class Bot < Thor
    include Interaction
    
    desc "readme", "Display helpful information for beginners"
    def readme
      STDOUT.write File.read("doc/readme.md")
    end
    
    no_tasks do
      # Write text to the file, unless file == '-', in which case, write to STDOUT
      def write_file(file_name, text)
        if file_name == '-'
          puts text
        else
          File.open(file_name, 'w') {|f| f.write(text)}
        end
      end
    end
    
    option "lines", :aliases=>'-l', :type=>'numeric', :desc=>'How many lines of the dump to show'
    option "frozen", :aliases=>'-f', :type=>'boolean', :desc=>'Display characters in frozen format (i.e. 5 per word)'
    option "escape", :aliases=>'-e', :type=>'boolean', :desc=>'Display unprintable characters as hex digits'
    option "offset", :aliases=>'-o', :type=>'numeric', :desc=>'Skip the first n lines'
    desc "dump FILE", "Dump a Honeywell file"
    def dump(file)
      archive = Archive.new
      file = archive.qualified_tape_file_name(file)
      decoder = GECOS::Decoder.new(File.read(file))
      archived_file = archive.file_path(file)
      archived_file = "--unknown--" unless archived_file
      puts "Archive for file #{archived_file}:"
      words = decoder.words
      Dump.dump(words, options)
    end
    
    UNPACK_OFFSET = 22
    option "inspect", :aliases=>'-i', :type=>'boolean', :desc=>"Display long format details for each line"
    option "deleted", :aliases=>'-d', :type=>'boolean', :desc=>"Display deleted lines (only with --inspect)"
    desc "unpack", "Unpack a file (Not frozen files -- use freezer subcommands for that)"
    def unpack(file)
      archive = Archive.new
      file = archive.qualified_tape_file_name(file)
      decoder = GECOS::Decoder.new(File.read(file))
      archived_file = archive.file_path(file)
      abort "Can't unpack file. It's a frozen file #{archived_file}" if Archive.frozen?(file)
      words = decoder.words
      offset = decoder.file_content_start + UNPACK_OFFSET
      offset_width = ('%o'%(words.size)).size
      line_count = 0
      loop do
        break if offset >= words.size
        break if words[offset] == 0170000
        line_length = (words[offset] & 0xffffc0000) >> 18
        lower_bits = words[offset] & 0x3ffff
        if line_length > 0x1ff # Deleted text; look for a word starting in 0x000 in the upper 9 bits
          original_offset = offset
          loop do
            offset += 1
            break if offset >= words.size
            # puts '%012o'%(words[offset]) + ':' + '%012o'%(words[offset] & 0xff1000000)
            if (words[offset] & 0xff1000000) == 0
              if options[:inspect] && options[:deleted]
                line = decoder.characters[(original_offset+1)*decoder.characters_per_word...offset*decoder.characters_per_word].sub(/\x7f*$/,'')
                puts %Q{0#{"%0#{offset_width}o"%original_offset} #{'%012o'%words[original_offset]} #{'%06o'%line_length} #{'%06o'%lower_bits} D #{line.inspect[1..-2]}}
              end
              offset += 1
              break
            end
          end
        else
          line = decoder.characters[(offset+1)*decoder.characters_per_word, line_length*decoder.characters_per_word].sub(/\x7f*$/,'')
          if options[:inspect]
            puts %Q{0#{"%0#{offset_width}o"%offset} #{'%012o'%words[offset]} #{'%06o'%line_length} #{'%06o'%lower_bits}   #{line.inspect[1..-2]}}
          else
            puts line
          end
          line_count += 1
          offset += line_length+1
        end
      end
    end

    option "inspect", :aliases=>'-i', :type=>'boolean', :desc=>"Display long format details for each line"
    desc "repair FILE TO", "Repair a file (Not frozen files -- use freezer subcommands for that)"
    def repair(file, to)
      archive = Archive.new
      file = archive.qualified_tape_file_name(file)
      decoder = GECOS::Decoder.new(File.read(file))
      archived_file = archive.file_path(file)
      abort "Can't unpack file. It's a frozen file #{archived_file}" if Archive.frozen?(file)
      content = decoder.words
      lines = nil
      loop do
        lines = []
        offset = decoder.file_content_start + UNPACK_OFFSET
        d = Decoder.new(nil)
        d.words = content
        loop do
          break if offset >= content.size
          line_length = (content[offset] & 0xffffc0000) >> 18
          lower_bits = content[offset] & 0x3ffff
          line = d.characters[(offset+1)*d.characters_per_word, line_length*d.characters_per_word].sub(/\x7f*$/,'')
          lines << {:offset=>offset, :content=>line}
          offset += line_length+1
        end
        flawed_line = lines.find {|l| l[:content].gsub(/\t/,' ') =~ /[[:cntrl:]]/}
        break unless flawed_line
        flaw_location = Decoder.find_flaw(flawed_line[:content])
        puts "Found a suspect line at #{'%o' % flawed_line[:offset]}: #{flawed_line[:content][0, flaw_location+5+1].inspect}"
        d1 = Decoder.new(nil)
        d1.words = content[flawed_line[:offset]..-1]
        remaining_characters = d1.characters
        search_start = flaw_location
        limit = nil
        start_location = nil
        end_location = nil
        next_line_end = nil
        from_text = nil
        to_text = nil
        loop do
          loop do
            if remaining_characters[(search_start+4)..-1] =~ /(\x7f+)|([[:cntrl:]])/m # +4 for the line length and flag characters
              last_line_end = $`.size
              limit = (search_start + last_line_end + 1 + 15)/16 + 1 # Final +1 to show an extra line of context
            else
              abort "Unable to find a later line ending."
            end
            Dump.dump(content, :offset=>flawed_line[:offset], :lines=>limit)
            break unless get_logical("Need to see more? ", :prompt_on=>STDERR)
            search_start += last_line_end + 1
          end
          clipped_section = content[flawed_line[:offset], limit*4]
          d = Decoder.new(nil)
          d.words = clipped_section
          chars = d.characters
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
          next_line_end = remaining_characters[end_location..-1] =~ /(\x7f+)|([[:cntrl:]])/m 
          abort "Can't find the end of the clipped line" unless next_line_end
          next_line_end += end_location + ($1||"").size - 1
          from_text = remaining_characters[4..next_line_end]
          STDERR.puts "from text: #{from_text.inspect}"
          to_text = (remaining_characters[4...(start_location+4)] + remaining_characters[end_location, next_line_end+1 - end_location]).sub(/\x7f+$/,'')
          STDERR.puts "Line after clipping:  #{to_text.inspect}"
          break if get_logical("Is this correct? ", :prompt_on=>STDERR)
        end
        if to_text.size%4 != 0
          to_text = to_text + "\x7f"*(4-to_text.size%4)
        end
        before_words = ((4+from_text.size)+3)/4
        after_words = ((4+to_text.size)+3)/4
        packed_line = [(to_text.size/4) << 18]
        chs = 4
        to_text.unpack('C*').each do |c|
          if chs >= 4
            packed_line << 0
            chs = 0
          end
          packed_line[-1] = (packed_line[-1]<<9) + (c & 0x1ff)
          chs += 1
        end
        content[flawed_line[:offset], before_words] = packed_line
        decoder.words = content
      end
      File.open(to,'w') {|f| f.write lines.map{|l| lines[:content]}.join("\n") }
    end
    
    no_tasks do
      def clean_file?(file)
        Decoder.clean? File.read(file)
      end
    end
    
    desc "test FILE", "Test a file for cleanness -- i.e. does it contain non-printable characters?"
    def test(file)
      if clean_file?(file)
        puts "File is clean"
      else
        puts "File is dirty"
      end
    end
    
    desc "describe FILE", "Display description information for a file"
    def describe(file)
      archive = Archive.new
      file = archive.qualified_tape_file_name(file)
      decoder = GECOS::Decoder.new(File.read(file))
      archived_file = archive.file_path(file)
      archive = decoder.file_archive_name
      subdirectory = decoder.file_subdirectory
      specification = decoder.file_specification
      description = decoder.file_description
      name = decoder.file_name
      path = decoder.file_path
      description = decoder.file_description
      frozen = Archive.frozen?(file)
      puts "Path             #{path}"
      puts "Archive          #{archive}"
      puts "Subdirectory     #{subdirectory}"
      puts "Name             #{name}"
      puts "Description      #{description}"
      puts "Specification    #{specification}"
      puts "Type:            #{frozen ? 'Frozen' : 'Normal'}"
    end

    register GECOS::FreezerBot, :freezer, "freezer", "Manage frozen Honeywell files"
    register GECOS::ArchiveBot, :archive, "archive", "Manage archives of Honeywell files"
  end
end