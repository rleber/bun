require 'thor'
require 'mechanize'
require 'fileutils'
require 'gecos/archive'
require 'gecos/file'
require 'gecos/archivebot'
require 'gecos/freezerbot'
require 'gecos/dump'
require 'gecos/array'

class GECOS
  class Bot < Thor
    
    desc "readme", "Display helpful information for beginners"
    def readme
      STDOUT.write File.read("doc/readme.md")
    end
    
    no_tasks do
      def get_regexp(pattern)
        Regexp.new(pattern)
      rescue
        nil
      end
    end
    
    SORT_VALUES = %w{tape file type date description size}
    TYPE_VALUES = %w{all frozen normal}
    desc "ls", "Display an index of archived files"
    option 'archive', :aliases=>'-a', :type=>'string',                               :desc=>'Archive location'
    option "descr",   :aliases=>"-d", :type=>'boolean',                              :desc=>"Include description"
    option "files",   :aliases=>"-f", :type=>'string',  :default=>'.*',              :desc=>"Show only files that match this Ruby Regexp, e.g. 'f.*oo\\.rb$'"
    option "frozen",  :aliases=>"-r", :type=>'boolean',                              :desc=>"Recursively include contents of freeze files"
    option "long",    :aliases=>"-l", :type=>'boolean',                              :desc=>"Display long format (incl. normal vs. frozen)"
    option 'path',    :aliases=>'-p', :type=>'boolean',                              :desc=>"Display paths for tape files"
    option "sort",    :aliases=>"-s", :type=>'string',  :default=>SORT_VALUES.first, :desc=>"Sort order for files (#{SORT_VALUES.join(', ')})"
    option "tapes",   :aliases=>"-t", :type=>'string',  :default=>'.*',              :desc=>"Show only tapes that match this Ruby Regexp, e.g. 'f.*oo\\.rb$'"
    option "type",    :aliases=>"-T", :type=>'string',  :default=>TYPE_VALUES.first, :desc=>"Show only files of this type (#{TYPE_VALUES.join(', ')})"
    def ls
      abort "Unknown --sort setting. Must be one of #{SORT_VALUES.join(', ')}" unless SORT_VALUES.include?(options[:sort])
      type_pattern = case options[:type].downcase
        when 'f', 'frozen'
          /^(frozen|archive)$/i
        when 'n', 'normal'
          /^normal$/i
        when '*','a','all'
          //
        else
          abort "Unknown --type setting. Should be one of #{TYPE_VALUES.join(', ')}"
        end
      file_pattern = get_regexp(options[:files])
      abort "Invalid --files pattern. Should be a valid Ruby regular expression (except for the delimiters)" unless file_pattern
      tape_pattern = get_regexp(options[:tapes])
      abort "Invalid --tapes pattern. Should be a valid Ruby regular expression (except for the delimiters)" unless tape_pattern
      directory = options[:archive] || Archive.location
      archive = Archive.new(directory)
      ix = archive.tapes

      # Retrieve file information
      file_info = []
      files = ix.each_with_index do |tape_name, i|
        file_name = archive.file_path(tape_name)
        tape_path = archive.expanded_tape_path(tape_name)
        display_name = options[:path] ? tape_path : tape_name
        frozen = Archive.frozen?(tape_path)
        archival_date = archive.archival_date(tape_name)
        archival_date_display = archival_date ? archival_date.strftime('%Y/%m/%d') : "n/a"
        friz = frozen ? 'Archive' : 'Normal'
        decoder = GECOS::Decoder.new(:data=>File.read(tape_path, 300))
        file_row = {'tape'=>display_name, 'type'=>friz, 'file'=>file_name, 'date'=>archival_date_display, 'size'=>decoder.word_count.decimal}
        if options[:descr]
          file_row['description'] = decoder.file_description
        end
        file_info << file_row
        if frozen && options[:frozen]
          defroster = Defroster.new(Decoder.new(:file=>tape_path))
          defroster.file_paths.each do |path|
            file_info << {'tape'=>display_name, 'type'=>'Frozen', 'file'=>path, 'archive'=>file_name}
          end
        end
      end
      file_info = file_info.select{|file| file['type']=~type_pattern && file['tape']=~tape_pattern && file['file']=~file_pattern }
      sorted_info = file_info.sort_by{|fi| [fi[options[:sort]||''], fi['file'], fi['tape']]} # Sort it in order

      # Display it
      table = []
      header = options[:long] ? %w{Tape Type Date Size File} : %w{Tape File}
      header << 'Description' if options[:descr]
      table << header
      sorted_info.each do |entry|
        table_row = entry.values_at(*(options[:long] ? %w{tape type date size file} : %w{tape file}))
        table_row << entry['description'] if options[:descr]
        table << table_row
      end
      table = table.justify_rows
      puts "Archive at #{directory}:"
      table.each do |row|
        puts row.join('  ')
      end
    end

    desc "dump FILE", "Dump a Honeywell file"
    option "escape",    :aliases=>'-e', :type=>'boolean', :desc=>'Display unprintable characters as hex digits'
    option "frozen",    :aliases=>'-f', :type=>'boolean', :desc=>'Display characters in frozen format (i.e. 5 per word)'
    option "lines",     :aliases=>'-l', :type=>'numeric', :desc=>'How many lines of the dump to show'
    option "offset",    :aliases=>'-o', :type=>'numeric', :desc=>'Skip the first n lines'
    option "unlimited", :aliases=>'-u', :type=>'boolean', :desc=>'Ignore the file size limit'
    def dump(file)
      archive = Archive.new
      file = archive.expanded_tape_path(file)
      decoder = GECOS::Decoder.new(:file=>file)
      archived_file = archive.file_path(file)
      archived_file = "--unknown--" unless archived_file
      puts "Archive for file #{archived_file}:"
      words = decoder.words
      Dump.dump(words, options)
    end
    
    desc "unpack FILE [TO]", "Unpack a file (Not frozen files -- use freezer subcommands for that)"
    option "delete",  :aliases=>'-d', :type=>'boolean', :desc=>"Keep deleted lines"
    option "inspect", :aliases=>'-i', :type=>'boolean', :desc=>"Display long format details for each line"
    option "log",     :aliases=>'-l', :type=>'string', :desc=>"Log status to specified file"
    option "warn",    :aliases=>'-w', :type=>'boolean', :desc=>"Warn if there are decoding errors"
    def unpack(file, to=nil)
      archive = Archive.new
      expanded_file = archive.expanded_tape_path(file)
      decoder = GECOS::Decoder.new(:file=>expanded_file)
      decoder.keep_deletes = true if options[:delete]
      archived_file = archive.file_path(expanded_file)
      abort "Can't unpack #{file}. It contains a frozen file: #{archived_file}" if Archive.frozen?(expanded_file)
      if options[:inspect]
        lines = []
        decoder.lines.each do |l|
          # p l
          # exit
          start = l[:start]
          line_descriptor = l[:descriptor]
          line_length = line_descriptor.half_word[0]
          line_flags = line_descriptor.half_word[1]
          line_codes = []
          line_codes << 'D' if l[:status]==:deleted
          line_codes << '+' if line_length > 0777 # Upper bits not zero
          line_codes << '*' if (line_descriptor & 0777) != 0600 # Bottom descriptor byte is normally 0600
          lines << %Q{#{"%06o" % start}: len #{"%06o" % line_length} (#{"%6d" % line_length}) [#{'%06o' % line_flags} #{'%-3s' % (line_codes.join)}] #{l[:raw].inspect}}
        end
        content = lines.join("\n")
      else
        content = decoder.text
      end
      shell = Shell.new
      shell.write to, content
      warn "Unpacked with #{decoder.errors} errors" if options[:warn] && decoder.errors > 0
      shell.log options[:log], "unpack #{to.inspect} from #{file.inspect} with #{decoder.errors} errors" if options[:log]
    end
    
    desc "scrub FILE", "Clean up backspaces and tabs in a file"
    option "tabs", :aliases=>'-t', :type=>'string', :desc=>"Set tab stops"
    def scrub(file)
      tabs = options[:tabs] || '80'
      system("cat #{file.inspect} | ruby -p -e '$_.gsub!(/_\\x8/,\"\")' | expand -t #{tabs}")
    end
    
    desc "test FILE", "Test a file for cleanness -- i.e. does it contain non-printable characters?"
    def test(file)
      if Decoder.clean?(File.read(file))
        puts "File is clean"
      else
        puts "File is dirty"
      end
    end
    
    desc "describe FILE", "Display description information for a file"
    def describe(file)
      archive = Archive.new
      tape_path = archive.expanded_tape_path(file)
      decoder = GECOS::Decoder.new(:file=>tape_path)
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
      puts "Size (words):    #{decoder.word_count.decimal.strip}"
      puts "Type:            #{frozen ? 'Frozen' : 'Normal'}"
      puts "Frozen files:    #{frozen_files.join(', ')}" if frozen
    end

    register GECOS::FreezerBot, :freezer, "freezer", "Manage frozen Honeywell files"
    register GECOS::ArchiveBot, :archive, "archive", "Manage archives of Honeywell files"
  end
end