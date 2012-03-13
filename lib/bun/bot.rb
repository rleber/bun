require 'thor'
require 'mechanize'
require 'fileutils'
require 'bun/archive'
require 'bun/file'
require 'bun/archivebot'
require 'bun/freezerbot'
require 'bun/dump'
require 'bun/array'
require 'pp'

class Bun
  class Bot < Thor
    
    desc "readme", "Display helpful information for beginners"
    def readme
      STDOUT.write ::File.read("doc/readme.md")
    end
    
    no_tasks do
      def get_regexp(pattern)
        Regexp.new(pattern)
      rescue
        nil
      end
    end
    
    SORT_VALUES = %w{tape file type date description size}
    TYPE_VALUES = %w{all frozen text huff}
    desc "ls", "Display an index of archived files"
    option 'archive', :aliases=>'-a', :type=>'string',                               :desc=>'Archive location'
    option "descr",   :aliases=>"-d", :type=>'boolean',                              :desc=>"Include description"
    option "files",   :aliases=>"-f", :type=>'string',  :default=>'',                :desc=>"Show only files that match this Ruby Regexp, e.g. 'f.*oo\\.rb$'"
    option "frozen",  :aliases=>"-r", :type=>'boolean',                              :desc=>"Recursively include contents of freeze files"
    option "long",    :aliases=>"-l", :type=>'boolean',                              :desc=>"Display long format (incl. text vs. frozen)"
    option 'path',    :aliases=>'-p', :type=>'boolean',                              :desc=>"Display paths for tape files"
    option "sort",    :aliases=>"-s", :type=>'string',  :default=>SORT_VALUES.first, :desc=>"Sort order for files (#{SORT_VALUES.join(', ')})"
    option "tapes",   :aliases=>"-t", :type=>'string',  :default=>'',                :desc=>"Show only tapes that match this Ruby Regexp, e.g. 'f.*oo\\.rb$'"
    option "type",    :aliases=>"-T", :type=>'string',  :default=>TYPE_VALUES.first, :desc=>"Show only files of this type (#{TYPE_VALUES.join(', ')})"
    # TODO Refactor tape/file patterns; use tape::file::shard syntax
    # TODO Speed this up; esp. ls with no options
    def ls
      abort "Unknown --sort setting. Must be one of #{SORT_VALUES.join(', ')}" unless SORT_VALUES.include?(options[:sort])
      type_pattern = case options[:type].downcase
        when 'f', 'frozen'
          /^(frozen|shard)$/i
        when 't', 'text'
          /^text$/i
        when 'h', 'huff', 'huffman'
          /^huff$/i
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
      ix = ix.select{|tape_name| tape_name =~ tape_pattern}
      file_info = []
      files = ix.each_with_index do |tape_name, i|
        file = archive.open(tape_name, :header=>true)
        file_name = file.path
        tape_path = file.tape
        type = file.file_type.to_s
        size = file.file_size
        # TODO Override file size, update date/time for frozen files
        if type=='frozen'
          index_date = file.update_time
          index_date_display = index_date.strftime('%Y/%m/%d %H:%M:%S')
          # TODO The following should no longer be necessary
          # size = frozen_file.file_size
        else
          # TODO Make this available from the file; requires saving the archive object
          index_date = archive.index_date(tape_name)
          index_date_display = index_date ? index_date.strftime('%Y/%m/%d') : "n/a"
        end
        display_name = options[:path] ? tape_path : tape_name
        file_row = {'tape'=>display_name, 'type'=>type, 'file'=>file_name, 'date'=>index_date_display, 'size'=>size}
        if options[:descr]
          file_row['description'] = file.description
        end
        file_info << file_row
        if type == "frozen" && options[:frozen]
          # TODO Include # shards
          file.shard_descriptors.each do |d|
            file_info << {'tape'=>display_name, 'type'=>'shard', 'file'=>d.path, 'archive'=>file_name, 'size'=>d.size, 'date'=>d.update_time.strftime('%Y/%m/%d %H:%M:%S')}
          end
        end
      end

      file_info = file_info.select{|file| file['type']=~type_pattern && file['file']=~file_pattern }
      sorted_info = file_info.sort_by{|fi| [fi[options[:sort]||''], fi['file'], fi['tape']]} # Sort it in order

      # Display it
      # TODO format times here
      table = []
      header = options[:long] ? %w{Tape Type Update Size File} : %w{Tape File}
      header << 'Description' if options[:descr]
      table << header
      sorted_info.each do |entry|
        table_row = entry.values_at(*(options[:long] ? %w{tape type date size file} : %w{tape file}))
        table_row << entry['description'] if options[:descr]
        table << table_row
      end
      table = table.justify_rows
      # TODO Move right justification to Array#justify_rows
      if options[:long]
        table.each do |row|
          row[3] = (' '*(row[3].size) + row[3].strip)[-(row[3].size)..-1] # Right justify
        end
      end
      puts "Archive at #{directory}:"
      if table.size <= 1
        puts "No matching files"
      else
        table.each do |row|
          puts row.join('  ')
        end
      end  
    end

    desc "dump FILE", "Dump a Honeywell file"
    option "escape",    :aliases=>'-e', :type=>'boolean', :desc=>'Display unprintable characters as hex digits'
    option "frozen",    :aliases=>'-f', :type=>'boolean', :desc=>'Display characters in frozen format (i.e. 5 per word)'
    option "lines",     :aliases=>'-l', :type=>'numeric', :desc=>'How many lines of the dump to show'
    option "offset",    :aliases=>'-o', :type=>'string', :desc=>'Start at word n (zero-based index; octal/hex values allowed)'
    option "unlimited", :aliases=>'-u', :type=>'boolean', :desc=>'Ignore the file size limit'
    # TODO Deblock option
    def dump(file_name)
      archive = Archive.new
      begin
        offset = options[:offset] ? eval(options[:offset]) : 0 # So octal or hex values can be given
      rescue => e
        abort "Bad value for --offset: #{e}"
      end
      file_path = archive.expanded_tape_path(file_name)
      file = Bun::File::Text.open(file_path)
      archived_file = file.path
      archived_file = "--unknown--" unless archived_file
      puts "Archive for file #{archived_file}:"
      words = file.words
      lc = Dump.dump(words, options.merge(:offset=>offset))
      puts "No data to dump" if lc == 0
    end
    
    desc "unpack FILE [TO]", "Unpack a file (Not frozen files -- use freezer subcommands for that)"
    option "delete",  :aliases=>'-d', :type=>'boolean', :desc=>"Keep deleted lines"
    option "inspect", :aliases=>'-i', :type=>'boolean', :desc=>"Display long format details for each line"
    option "log",     :aliases=>'-l', :type=>'string', :desc=>"Log status to specified file"
    option "warn",    :aliases=>'-w', :type=>'boolean', :desc=>"Warn if there are decoding errors"
    # TODO combine with other forms of read (e.g. thaw)
    # TODO rename bun read
    def unpack(file_name, to=nil)
      archive = Archive.new
      expanded_file = archive.expanded_tape_path(file_name)
      file = File::Text.open(expanded_file)
      file.keep_deletes = true if options[:delete]
      archived_file = archive.file_path(expanded_file)
      abort "Can't unpack #{file_name}. It contains a frozen file_name: #{archived_file}" if File.frozen?(expanded_file)
      if options[:inspect]
        lines = []
        file.lines.each do |l|
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
        content = file.text
      end
      shell = Shell.new
      shell.write to, content
      warn "Unpacked with #{file.errors} errors" if options[:warn] && file.errors > 0
      shell.log options[:log], "unpack #{to.inspect} from #{file_name.inspect} with #{file.errors} errors" if options[:log]
    end
    
    desc "scrub FILE", "Clean up backspaces and tabs in a file"
    option "tabs", :aliases=>'-t', :type=>'string', :desc=>"Set tab stops"
    def scrub(file)
      tabs = options[:tabs] || '80'
      system("cat #{file.inspect} | ruby -p -e '$_.gsub!(/_\\x8/,\"\")' | expand -t #{tabs}")
    end
    
    desc "test FILE", "Test a file for cleanness -- i.e. does it contain non-printable characters?"
    def test(file)
      if ::File.clean?(::File.read(file))
        puts "File is clean"
      else
        puts "File is dirty"
      end
    end
    
    DATE_FORMAT = '%Y/%m/%d'
    TIME_FORMAT = DATE_FORMAT + ' %H:%M:%S'
    SHARDS_ACROSS = 5
    desc "describe FILE", "Display description information for a file"
    def describe(file_name)
      archive = Archive.new
      file          = archive.open(file_name, :header=>true)
      type          = file.file_type
      shards        = file.shard_names
      index_date    = file.index_date
      index_date_display = index_date ? index_date.strftime('%Y/%m/%d') : "n/a"
      
      # TODO Refactor using Array#justify_rows
      puts "Tape:            #{file.tape}"
      puts "Tape path:       #{file.tape_path}"
      puts "Archived file:   #{file.path}"
      puts "Owner:           #{file.owner}"
      puts "Subdirectory:    #{file.subdirectory}"
      puts "Name:            #{file.name}"
      puts "Description:     #{file.description}"
      puts "Specification:   #{file.specification}"
      puts "Index date:      #{index_date_display}"
      if type == :frozen
        puts "Updated at:      #{file.update_time.strftime(TIME_FORMAT)}"
      end
      puts "Size (words):    #{file.size}"
      puts "Type:            #{type.to_s.sub(/^./) {|m| m.upcase}}"

      if shards.size > 0
        # Display shard information in a table, SHARDS_ACROSS shards per row,
        # Multiple rows of information for each shard
        puts
        puts "Shards:"
        grand_table = []
        columns = 0
        titles = %w{Name: Path: Updated\ at: Size\ (words):}
        i = 0
        loop do
          break if i >= shards.size
          table = [titles]
          SHARDS_ACROSS.times do |j|
            if i >= shards.size
              column = [""]*4
            else
              shard = shards[i]
              d = file.shard_descriptor(shard)
              column = [shard, d.path, d.update_time.strftime(TIME_FORMAT), d.size]
            end
            table << column
            i += 1
          end
          table.each_with_index do |column, j|
            if grand_table[j]
              grand_table[j] << ''
              grand_table[j] += column
            else
              grand_table[j] = column.dup
            end
          end
        end
        row_table = grand_table.justify_columns.transpose
        puts row_table.map{|row| '  ' + row.join('  ')}.join("\n")
      end
    end

    register Bun::FreezerBot, :freezer, "freezer", "Manage frozen Honeywell files"
    register Bun::ArchiveBot, :archive, "archive", "Manage archives of Honeywell files"
  end
end