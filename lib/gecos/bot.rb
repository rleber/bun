require 'thor'
require 'mechanize'
require 'fileutils'
require 'gecos/archive'
require 'gecos/decoder'
require 'gecos/defroster'
require 'gecos/archivebot'
require 'gecos/freezerbot'
require 'gecos/dump'

class GECOS
  class Bot < Thor
    
    desc "readme", "Display helpful information for beginners"
    def readme
      STDOUT.write File.read("doc/readme.md")
    end
    
    option "lines", :aliases=>'-l', :type=>'numeric', :desc=>'How many lines of the dump to show'
    option "frozen", :aliases=>'-f', :type=>'boolean', :desc=>'Display characters in frozen format (i.e. 5 per word)'
    option "escape", :aliases=>'-e', :type=>'boolean', :desc=>'Display unprintable characters as hex digits'
    option "offset", :aliases=>'-o', :type=>'numeric', :desc=>'Skip the first n lines'
    desc "dump FILE", "Dump a Honeywell file"
    def dump(file)
      archive = Archive.new
      file = archive.expanded_tape_path(file)
      decoder = GECOS::Decoder.new(:data=>File.read(file))
      archived_file = archive.file_path(file)
      archived_file = "--unknown--" unless archived_file
      puts "Archive for file #{archived_file}:"
      words = decoder.words
      Dump.dump(words, options)
    end
    
    UNPACK_OFFSET = 22
    option "inspect", :aliases=>'-i', :type=>'boolean', :desc=>"Display long format details for each line"
    option "delete", :aliases=>'-d', :type=>'boolean', :desc=>"Keep deleted lines"
    option "warn", :aliases=>'-w', :type=>'boolean', :desc=>"Warn if there are decoding errors"
    option "log", :aliases=>'-l', :type=>'string', :desc=>"Log status to specified file"
    desc "unpack FILE [TO]", "Unpack a file (Not frozen files -- use freezer subcommands for that)"
    def unpack(file, to=nil)
      archive = Archive.new
      expanded_file = archive.expanded_tape_path(file)
      decoder = GECOS::Decoder.new(:data=>File.read(expanded_file))
      decoder.keep_deletes = true if options[:delete]
      archived_file = archive.file_path(expanded_file)
      abort "Can't unpack #{file}. It contains a frozen file: #{archived_file}" if Archive.frozen?(expanded_file)
      if options[:inspect]
        lines = []
        decoder.lines.each do |l|
          start = l[:start]
          line_descriptor = l[:descriptor]
          line_length = decoder.line_length(line_descriptor)
          line_flags = decoder.line_flags(line_descriptor)
          line_codes = []
          line_codes << 'D' if l[:status]==:deleted
          line_codes << '+' if line_length > 0777 # Upper bits not zero
          line_codes << '*' if (line_descriptor & 0777) != 0600 # Bottom descriptor byte is normally 0600
          lines << %Q{#{"%06o" % start}: len #{"%06o" % line_length} (#{"%6d" % line_length}) [#{'%06o' % line_flags} #{'%-3s' % (line_codes.join)}] #{l[:raw].inspect}}
        end
        content = lines.join("\n")
      else
        content = decoder.content
      end
      shell = Shell.new
      shell.write to, content
      warn "Unpacked with #{decoder.errors} errors" if options[:warn] && decoder.errors > 0
      shell.log options[:log], "unpack #{to.inspect} from #{file.inspect} with #{decoder.errors} errors" if options[:log]
    end
    
    no_tasks do
      def explore_line(decoder, i, l)
        line_descriptor = l[:descriptor]
        start = l[:start]
        line_length = decoder.line_length(line_descriptor)
        line_flags = decoder.line_flags(line_descriptor)
        delete_flag = l[:status]==:deleted ? 'D' : ' '
        descriptor_chars = decoder.extract_characters(line_descriptor)
        puts %Q{##{'%4d' % i} #{"%06o" % start}: len #{"%06o" % line_length} (#{"%6d" % line_length}) [#{'%06o' % line_flags} #{delete_flag}] #{'%-18s' % (descriptor_chars.inspect)} #{l[:raw].inspect}}
      end
    end
    
    desc "scrub FILE", "Clean up backspaces and tabs in a file"
    option "tabs", :aliases=>'-t', :type=>'string', :desc=>"Set tab stops"
    def scrub(file)
      tabs = options[:tabs] || '70'
      system("cat #{file.inspect} | ruby -p -e '$_.gsub!(/_\\x8/,\"\")' | expand -t #{tabs}")
    #   
    #   tabs = (options[:tabs]||'').split(/,/).map{|t| t.to_i}
    #   if file=='-'
    #     f = STDIN
    #   else
    #     f = File.open(file, 'r')
    #   end
    #   f.each do |line|
    #     line = line.gsub(/_\x8/,'')   # Remove underlines
    #     count = 0
    #     loop do
    #       break unless line =~ /\t/
    #       prefix = $`
    #       suffix = $'
    #       loop do
    #         break unless count < tabs.size
    #         break if prefix.size < tabs[count]
    #         count += 1
    #       end
    #       tab_chars = count < tabs.size ?  ' ' * (tabs[count]-prefix.size) : ' '
    #       line = prefix + tab_chars + suffix
    #       count += 1
    #     end
    #     puts line
    #   end
    # ensure
    #   f.close unless file=='-'
    end
    
    DEFAULT_CONTEXT_LINES = 2
    desc "explore FILE", "Explore the contents of a normal file"
    option 'context', :aliases=>'-c', :type=>'numeric', :desc=>"Show how many lines of context before each special line? (Default #{DEFAULT_CONTEXT_LINES})"
    def explore(file)
      archive = Archive.new
      expanded_file = archive.expanded_tape_path(file)
      decoder = GECOS::Decoder.new(:data=>File.read(expanded_file))
      decoder.keep_deletes = true
      archived_file = archive.file_path(expanded_file)
      abort "Can't unpack #{file}. It contains a frozen file: #{archived_file}" if Archive.frozen?(expanded_file)
      decoder.lines.each_with_index do |l, i|
        line_descriptor = l[:descriptor]
        next if l[:descriptor] & 0777 == 0600
        puts
        ([i-DEFAULT_CONTEXT_LINES, 0].max..i).each do |j|
          explore_line(decoder, j, decoder.lines[j])
        end
      end
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
      tape_path = archive.expanded_tape_path(file)
      decoder = GECOS::Decoder.new(:data=>File.read(tape_path))
      archived_file = archive.file_path(tape_path)
      archive_name = decoder.file_archive_name
      subdirectory = decoder.file_subdirectory
      specification = decoder.file_specification
      description = decoder.file_description
      name = decoder.file_name
      path = decoder.file_path
      description = decoder.file_description
      archival_date = archive.archival_date(file)
      archival_date_display = archival_date ? archival_date.strftime('%Y/%m/%d') : "n/a"
      frozen = Archive.frozen?(tape_path)
      frozen_files = Defroster.new(decoder).file_names.sort if frozen
      puts "Tape             #{file}"
      puts "Tape path        #{tape_path}"
      puts "Archived file    #{path}"
      puts "Archive          #{archive_name}"
      puts "Subdirectory     #{subdirectory}"
      puts "Name             #{name}"
      puts "Description      #{description}"
      puts "Specification    #{specification}"
      puts "Archival date:   #{archival_date_display}"
      puts "Type:            #{frozen ? 'Frozen' : 'Normal'}"
      puts "Frozen files:    #{frozen_files.join(', ')}" if frozen
    end

    register GECOS::FreezerBot, :freezer, "freezer", "Manage frozen Honeywell files"
    register GECOS::ArchiveBot, :archive, "archive", "Manage archives of Honeywell files"
  end
end