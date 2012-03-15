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
    
    SORT_VALUES = %w{tape file type updated description size}
    SORT_FIELDS = {
      :description => :description,
      :file        => :path,
      :size        => :file_size,
      :tape        => :tape_name,
      :type        => :file_type,
      :updated     => :updated,
    }
    TYPE_VALUES = %w{all frozen text huff}
    DATE_FORMAT = '%Y/%m/%d'
    TIME_FORMAT = DATE_FORMAT + ' %H:%M:%S'
    FIELD_CONVERSIONS = {
      :updated     => lambda {|f| f.nil? ? 'n/a' : f.strftime(f.is_a?(Time) ? TIME_FORMAT : DATE_FORMAT) },
      :file_type   => lambda {|f| f.to_s.sub(/^./) {|m| m.upcase} },
      :shard_count => lambda {|f| f==0 ? '' : f },
    }
    FIELD_HEADINGS = {
      :description => 'Description',
      :file_size   => 'Size',
      :file_type   => 'Type',
      :path        => 'File',
      :shard_count => 'Shards',
      :tape_name   => 'Tape',
      :tape_path   => 'Tape',
      :updated     => 'Updated',
    }
    DEFAULT_VALUES = {
      :file_size   => 0,
      :shard_count => 0,
      :updated     => Time.now,
    }
    
    # TODO Reorder tasks (split in separate files?)
    desc "ls", "Display an index of archived files"
    option 'archive', :aliases=>'-a', :type=>'string',                               :desc=>'Archive location'
    option "build",   :aliases=>"-b", :type=>'boolean',                              :desc=>"Don't rely on archive index; always build information from source file"
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
      type_pattern = case options[:type].downcase
        when 'f', 'frozen'
          /^(frozen|shard)$/i
        when 't', 'text'
          /^text$/i
        when 'h', 'huff', 'huffman'
          /^huffman$/i
        when '*','a','all'
          //
        else
          abort "!Unknown --type setting. Should be one of #{TYPE_VALUES.join(', ')}"
        end
      file_pattern = get_regexp(options[:files])
      abort "!Invalid --files pattern. Should be a valid Ruby regular expression (except for the delimiters)" unless file_pattern
      tape_pattern = get_regexp(options[:tapes])
      abort "!Invalid --tapes pattern. Should be a valid Ruby regular expression (except for the delimiters)" unless tape_pattern
      directory = options[:archive] || Archive.location

      fields =  options[:path] ? [:tape_path] : [:tape_name]
      fields += [:file_type, :updated, :file_size] if options[:long]
      fields += [:path]
      fields += [:shard_count] if options[:long]
      fields += [:description] if options[:descr]

      if options[:sort]
        sort_field = SORT_FIELDS[options[:sort].to_sym]
        abort "!Unknown --sort setting. Must be one of #{SORT_VALUES.join(', ')}" unless sort_field
        sort_fields = [sort_field.to_sym, :tape_name, :path]
      else
        sort_fields = [:tape_name, :path]
      end
      if options[:path]
        sort_fields = sort_fields.map {|f| f==:tape_name ? :tape_path : f }
      end
      sort_fields.each do |sort_field|
        abort "!Can't sort by #{sort_field}. It isn't included in this format" unless fields.include?(sort_field)
      end

      # Retrieve file information
      archive = Archive.new(directory)
      ix = archive.tapes
      # TODO Refactor using archive.select
      ix = ix.select{|tape_name| tape_name =~ tape_pattern}
      file_info = []
      files = ix.each_with_index do |tape_name, i|
        file_descriptor = archive.descriptor(tape_name, :build=>options[:build])
        file_row = fields.inject({}) {|hsh, f| hsh[f] = file_descriptor[f]; hsh }
        file_info << file_row
        if options[:frozen] && file_descriptor[:file_type] == :frozen
          file_descriptor[:shards].each do |d|
            file_info << fields.inject({}) {|hsh, f| hsh[f] = d[f]; hsh }
          end
        end
      end
      
      file_info = file_info.select{|file| file[:file_type].to_s=~type_pattern && file[:path]=~file_pattern }
      sorted_info = file_info.sort_by do |fi|
        sort_fields.map{|f| fi[f].nil? ? DEFAULT_VALUES[f]||'' : fi[f] }
      end
      
      formatted_info = sorted_info
      formatted_info.each do |fi|
        fi.keys.each do |k|
          fi[k] = FIELD_CONVERSIONS[k].call(fi[k]) if FIELD_CONVERSIONS[k]
        end
      end

      table = []
      headings = FIELD_HEADINGS.values_at(*fields)
      table << headings
      formatted_info.each do |entry|
        table << entry.values_at(*fields)
      end
      table = table.justify_rows
      # TODO Move right justification to Array#justify_rows
      [:file_size, :shard_count].each do |f|
        if ix = fields.index(f)
          table.each do |row|
            row[ix] = (' '*(row[ix].size) + row[ix].strip)[-(row[ix].size)..-1] # Right justify
          end
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

    desc "dump TAPE", "Dump a Honeywell file"
    option 'archive',   :aliases=>'-a', :type=>'string',  :desc=>'Archive location'
    option "escape",    :aliases=>'-e', :type=>'boolean', :desc=>'Display unprintable characters as hex digits'
    option "frozen",    :aliases=>'-f', :type=>'boolean', :desc=>'Display characters in frozen format (i.e. 5 per word)'
    option "lines",     :aliases=>'-l', :type=>'numeric', :desc=>'How many lines of the dump to show'
    option "offset",    :aliases=>'-o', :type=>'string',  :desc=>'Start at word n (zero-based index; octal/hex values allowed)'
    option "unlimited", :aliases=>'-u', :type=>'boolean', :desc=>'Ignore the file size limit'
    # TODO Deblock option
    def dump(file_name)
      directory = options[:archive] || Archive.location
      archive = Archive.new(directory)
      begin
        offset = options[:offset] ? eval(options[:offset]) : 0 # So octal or hex values can be given
      rescue => e
        abort "!Bad value for --offset: #{e}"
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
    
    desc "unpack TAPE [TO]", "Unpack a file (Not frozen files -- use freezer subcommands for that)"
    option 'archive', :aliases=>'-a', :type=>'string',  :desc=>'Archive location'
    option "delete",  :aliases=>'-d', :type=>'boolean', :desc=>"Keep deleted lines"
    option "inspect", :aliases=>'-i', :type=>'boolean', :desc=>"Display long format details for each line"
    option "log",     :aliases=>'-l', :type=>'string',  :desc=>"Log status to specified file"
    option "warn",    :aliases=>'-w', :type=>'boolean', :desc=>"Warn if there are decoding errors"
    # TODO combine with other forms of read (e.g. thaw)
    # TODO rename bun read
    def unpack(file_name, to=nil)
      directory = options[:archive] || Archive.location
      archive = Archive.new(directory)
      file = archive.open(file_name)
      file.keep_deletes = true if options[:delete]
      archived_file = file.path
      abort "!Can't unpack #{file_name}. It contains a frozen file_name: #{archived_file}" if file.file_type == :frozen
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
    
    desc "check FILE", "Test a file for cleanness -- i.e. does it contain non-printable characters?"
    def check(file)
      if File.clean?(::File.read(file))
        puts "File is clean"
      else
        abort "File is dirty"
      end
    end
    
    SHARDS_ACROSS = 5
    desc "describe TAPE", "Display description information for a file"
    option 'archive', :aliases=>'-a', :type=>'string', :desc=>'Archive location'
    def describe(file_name)
      directory = options[:archive] || Archive.location
      archive = Archive.new(directory)
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
        # TODO Modify Array extensions and refactor
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
    
    desc "cat TAPE", "Copy a file to $stdout"
    # TODO Refactor :archive as a global option?
    option 'archive', :aliases=>'-a', :type=>'string', :desc=>'Archive location'
    def cat(tape)
      directory = options[:archive] || Archive.location
      archive = Archive.new(directory)
      archive.open(tape) {|f| $stdout.write f.read }
    end

    desc "cp TAPE [DESTINATION]", "Copy a file"
    # TODO Refactor :archive as a global option?
    option 'archive', :aliases=>'-a', :type=>'string', :desc=>'Archive location'
    def cp(tape, dest = nil)
      directory = options[:archive] || Archive.location
      archive = Archive.new(directory)
      unless dest.nil? || dest == '-'
        dest = ::File.join(dest, ::File.basename(tape)) if ::File.directory?(dest)
      end
      archive.open(tape) {|f| Shell.new(:quiet=>true).write dest, f.read }
    end
    
    desc "test", "test this software"
    def test
      exec "thor spec"
    end

    register Bun::FreezerBot, :freezer, "freezer", "Manage frozen Honeywell files"
    register Bun::ArchiveBot, :archive, "archive", "Manage archives of Honeywell files"
  end
end