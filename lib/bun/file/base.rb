#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

require 'lib/bun/file/descriptor'
require 'lib/string'
require 'yaml'
require 'date'
require 'tmpdir'

module Bun

  class File < ::File
    
    class BadFileFormat < RuntimeError; end
    class BadBlockError < RuntimeError; end
    class ReadError < ArgumentError; end

    class << self
      
      @@stdin_cache = nil  # Content of STDIN (we cache it, to allow rereading)
      @@last_read = nil    # Name of the last file read, except STDIN (we save it, to avoid rereading)
      @@last_content = nil # Content of the last file read (except STDIN)
      @@messages = {}

      def messages
        @@messages
      end

      def clear_messages(path=nil)
        if path
          path = ::File.expand_path(path)
          @@messages[path] = []
        else
          @@messages = {}
        end
      end

      def add_message(path,msg=nil)
        case msg
        when nil
          # Do nothing
        when Array
          msg.each {|m| add_msg(path, m)}
        else
          path = ::File.expand_path(path)
          @@messages[path] ||= []
          @@messages[path] << msg
        end
      end
      alias_method :add_messages, :add_message

      def replace_messages(path=nil,msg=nil)
        clear_messages(path)
        add_message path,msg
      end

      def all_messages(path=nil)
        if path
          path = ::File.expand_path(path)
          @@messages[path] || []
        else
          @@messages.keys.sort.map {|path| @@messages[path]}.flatten
        end
      end

      def message_count(path=nil)
        if path
          path = ::File.expand_path(path)
          (@@messages[path]||[]).size
        else
          @@messages.values.map{|msgs| msgs.size}.sum
        end
      end

      def warn_messages(path=nil)
        return if message_count(path)==0
        all_messages(path).each {|msg| warn msg}
      end
      
      # Allows STDIN to be read multiple times
      def read(*args)
        options = args.last.is_a?(Hash) ? args.pop : {}
        path = args.shift
        text = if path == '-'
          Bun.cache(:read_stdin, :stdin) { $stdin.read.force_encoding('ascii-8bit') }
        else
          Bun.cache(:read_path, File.expand_path(path)) do
            stop "!File #{path} does not exist" unless File.exists?(path)
            Bun.cache(:read_path, path) do
              (::File.read(path) || '').force_encoding('ascii-8bit') # We cache entire file
            end
          end
        end
        case args.size
        when 0
          # Do nothing
        when 1 # Read length specified
          raise ReadError, "Unable to handle read parameter #{args[0].inspect}" unless args[0].is_a?(Numeric)
          text = text[0,args[0]]
        when 2 # Read length and offset specified
          raise ReadError, "Unable to handle first read parameter #{args[0].inspect}" unless args[0].is_a?(Numeric)
          raise ReadError, "Unable to handle second read parameter #{args[1].inspect}" unless args[1].is_a?(Numeric)
          text = text[args[1], args[0]]
        else
          raise ReadError, "Unable to handle first read parameters #{args.inspect}"
        end
        text
      end

      def relative_path(*f)
        options = {}
        if f.last.is_a?(Hash)
          options = f.pop
        end
        relative_to = options[:relative_to] || ENV['HOME']
        File.expand_path(File.join(*f), relative_to).sub(/^#{Regexp.escape(relative_to)}\//,'')
      end

      def temporary_file_name(seed)
        Dir::Tmpname.make_tmpname [Dir::Tmpname.tmpdir, seed], nil
      end

      def temporary_file(seed, options={}, &blk)
        file = Tempfile.new(seed)
        return file unless block_given?
        begin
          yield(file)
        ensure
          file.close unless options[:keep]
        end
      end

      def temporary_directory(seed, options={}, &blk)
        directory_name = Dir.mktmpdir(seed)
        return directory_name unless block_given?
        begin
          yield(directory_name)
        ensure
          Dir.rmdir(directory_name) unless options[:keep]
        end
      end

      # def control_character_counts(path)
      #   Bun.readfile(path).control_character_counts
      # end
      
      def baked_file_and_data(path, options={})
        if options[:promote]
          if File.format(path) == :baked
            [nil, read(path)]
          elsif File.type(path) == :frozen && !options[:shard]
            files = File::Decoded.open(path, :promote=>true, :expand=>true)
            data = Bun.cache(:baked_expanded_data, File.expand_path(path)) { files.values.map{|f| f.data}.join }
            [files.values.first, data]
          else
            f = File::Decoded.open(path, :promote=>true, :shard=>options[:shard])
            data = Bun.cache(:baked_unexpanded_data, [File.expand_path(path), options[:shard]]) { f.data }
            [f, data]
          end
        else
          [nil, read(path)]
        end
      end

      def file_for_expression(path, options={})
        case File.format(path)
        when :packed, :unpacked
          f = if options[:promote]
            File::Unpacked.open(path, :promote=>true)
          else
            File::Packed.open(path)
          end
          merge_shard_descriptor(f, options[:shard]) if options[:shard]
          f
        else
          File.open(path)
        end
      end

      def merge_shard_descriptor(f, shard)
        shard_entry = f.descriptor.shards[shard]
        shard_entry.keys.each do |key|
          new_key = "shard_#{key}".to_sym
          f.descriptor.merge!(new_key=>shard_entry[key])
        end
        f.descriptor.delete(:shards)
        f.descriptor.delete('shards')
      end
      
      def baked_data(path, options={})
        _, data = baked_file_and_data(path, options)
        data
      end
      
      def trait(file, trait, options={})
        Bun::File.create_expression(file, trait, 
          promote: options[:promote], shard: options[:shard], raise: options[:raise])
      end
      
      def create_examination(path, analysis, options={})
        examiner = String::Trait.create(analysis, options)
        examiner.attach(:string) { baked_data(path, options) } # Lazy evaluation of file contents
        examiner.attach(:file, self)
        examiner
      end
      protected :create_examination
      
      def create_expression(path, expression, options={})
        expression_options = options.merge(expression: expression, path: path, raise: options[:raise])
        evaluator = Bun::Expression.new(expression_options)
        evaluator.attach(:file) { file_for_expression(path, options) }
        evaluator.attach(:data) { baked_data(path, options) }
        evaluator
      end
      protected :create_expression
  
      def binary?(path)
        prefix = File.read(path, 4)
        prefix != "---\n" # YAML prefix; one of the unpacked formats
      end
      
      def nonpacked?(path)
        prefix = File.read(path, 21)
        prefix == "---\n:identifier: Bun\n" # YAML prefix with identifier
      end
      
      PACKED_FILE_SIGNATURE = "\x0\x0\x40" # Packed files always start with this

      def index_file_for(path)
        dir = File.dirname(path)
        path = File.basename(path)
        loop do
          index_file_path = File.join(dir, Bun::DEFAULT_BAKED_INDEX_DIRECTORY, path+Bun::INDEX_FILE_EXTENSION)
          return index_file_path if File.exists?(index_file_path)
          break if dir == "/" || dir == "."
          path = File.join(File.basename(dir), path)
          dir = File.dirname(dir)
        end
        nil
      end

      def packed?(path)
        return false if nonpacked?(path)
        if File.read(path, PACKED_FILE_SIGNATURE.size).force_encoding('ascii-8bit') == PACKED_FILE_SIGNATURE 
          res = begin
            File::Packed.open(path, force: true)
          rescue => e
            false
          end
          index_file_for(path) ? false : res # If .INDEX... exists, then it's baked, not packed
        else
          false
        end
      end
      
      def open(path, options={}, &blk)
        # TODO But format opens and reads the file, too...
        case fmt = format(path)
        when :packed
          File::Packed.open(path, options, &blk)
        when :unpacked, :cataloged
          File::Unpacked.open(path, options, &blk)
        when :decoded
          File::Decoded.open(path, options, &blk)
        when :baked
          File::Baked.open(path, &blk)
        else
          # TODO Why not?
          raise BadFileFormat, "Can't open file of this format: #{fmt.inspect}"
        end
      end
      
      def type(path)
        # return :packed if packed?(path)
        begin
          f = File::Unpacked.open(path, promote: true) 
          f.type
        rescue
          raise
          :unknown
        end
      end
      
      def format(path)
        res = if packed?(path)
          :packed
        elsif binary?(path)
          :baked
        else
          d = File::Unpacked.build_descriptor_from_file(path)
          d.format
        end
        res
      end
      
      def format_level(fmt)
        [:packed, :unpacked, :decoded, :baked].index(fmt)
      end

      def file_outgrades?(path, level)
        format_level(format(path)) > format_level(level)
      end
      
      def descriptor(path, options={})
        # TODO This is smelly (but necessary, in case the file was opened with :force)
        open(path, :force=>true) {|f| f.descriptor }
      rescue Errno::ENOENT => e
        return nil if options[:allow]
        raise
      end

      def timestamp(file)
        time = if directory?(file)
          leaves(file).map{|f| timestamp(f)}.min
        else
          descr = File::Unpacked.build_descriptor_from_file(file) rescue nil
          descr && descr.timestamp
        end
        time || Time.now
      end

      def leaves(path)
        Dir[join(path, '**', '*')].reject{|f| directory?(f)}
      end
      
      # Convert from packed format to unpacked (i.e. YAML)
      def unpack(path, to, options={})
        if File.exists?(to)
          unless options[:force]
            warn "Skipping unpack: #{to} already exists" unless options[:quiet]
            return
          end
        end
        case format(path)
        when :packed
          open(path) do |f|
            cvt = f.unpack(fix: options[:fix])
            cvt.descriptor.tape = options[:tape] if options[:tape]
            cvt.descriptor.merge!(:unpack_time=>Time.now, :unpacked_by=>Bun.expanded_version)
            cvt.write(to)
          end
        else
          Shell.new.cp(path, to)
        end
      end

      def decode(path, to, options={}, &blk)
        self.clear_messages
        case format(path)
        when :packed
          File::Unpacked.open(path, options.merge(promote: true)) do |f|
            f.decode(to, options, &blk)
          end
        else
          File.open(path, options) do |f|
            f.decode(to, options, &blk)
          end
        end
      end

      def bake(path, to, options={})
        scrub = options.delete(:scrub)
        case format(path)
        when :baked, :decoded
          File.open(path, options) {|f| f.bake(to, scrub: scrub, index: options[:index])}
        else
          File::Decoded.open(path, options.merge(promote: true)) {|f| f.bake(to, scrub: scrub, index: options[:index])}
        end
      end

      SCRUB_COLUMN_WIDTH = 60
      SCRUB_FORM_FEED    = %q{"\n" + "-"*column_width + "\n"}
      SCRUB_VERTICAL_TAB = %q{"\n"}

      def scrub(from, to, options={})
        column_width = options[:width] || SCRUB_COLUMN_WIDTH
        form_feed = options[:ff] || eval(SCRUB_FORM_FEED)
        vertical_tab = options[:vtab] || eval(SCRUB_VERTICAL_TAB)
        text = File.read(from)
        scrubbed_text = text.scrub(:column_width=>column_width, :form_feed=>form_feed, :vertical_tab=>vertical_tab)
        Shell.new.write(to, scrubbed_text)
      end

      def expand_path(path, relative_to=nil)
        path == '-' ? path : super(path, relative_to)
      end

      def get_shard(path)
        if path =~ /^(.*?)\[(.*)\]$/ # Has shard specifier
          [$1, $2]
        else
          [path, nil]
        end
      end

      def shards(file)
        File.open(file) {|f| f.descriptor.shards || [] }
      end

      def shard_names(file)
        shards(file).map {|shard| shard.name }
      end

      # Does this path (or any part of its directory structure) conflict with an existing file?
      def conflicts?(path, options={})
        return false if path.nil? # Signifies "no output"; therefore, no conflict
        return false if path=='-' # Signifies STDOUT; never a conflict
        return false if File.directory?(path) && options[:directories_okay]
        return path  if File.exists?(path)
        dir = File.dirname(path)
        return false if dir=='.' || dir=='/'
        return conflicts?(dir, directories_okay: true)
      end

      # Note: returns an array of files that conflict with a proposed new file f. The
      def conflicting_files(f)
        ext = File.nondate_extname(f)
        conflict_base = f.sub(/#{Regexp.escape(ext)}$/,'')
        pat = /^#{Regexp.escape(conflict_base)}(?:\.V\d+)?#{Regexp.escape(ext)}$/
        Dir.glob(conflict_base+'*')
           .select {|file| file =~ pat }
      end

      def nondate_extname(path)
        ext = File.extname(path)
        ext = "" if ext =~ /^\.\d{4}(?:_\d{8})?(?:_\d{6})?$/ # Date suffix doesn't count as an extension
        ext
      end

      def directory_count(path)
        Dir[join(path, '*')].size
      end

      def path_heirarchy(path)
        case path.to_s
        when ""
          return []
        when ".", "/"
          return [path]
        end
        return path_heirarchy(dirname(path)) + [path]
      end

      def ancestor_directories(path)
        h = path_heirarchy(path)
        h.pop
        h
      end

      # Create a set of moves that will merge a set of files to a destination without conflicts.
      # Where necessary, add version numbers to the files to avoid stomping any file
      #
      # This method returns an array of moves that avoids conflicts. Each element in the array is 
      # a hash in the form {:from=>from_file, :to=>to_file, :version=>99}. The moves MUST be executed
      # in the order specified to guarantee avoiding conflicts!
      #
      # If there is no conflict, this method returns [{from: file, to: new_file, version: nil}]
      #
      # Rules for moving files
      #   1. a/b/c/d (without extension) moves to a/b/c/d.v1 (but see below)
      #   2. a/b/c/d...y.ext (with extension) moves to a/b/c/d...y.v99.ext (but see below)
      #   3. a/b/c/d...v3.ext doesn't move
      #   4. Version numbers are always assigned in ascending order of file date
      #
      # Arguments:
      #   files is an array of (fully qualified) file names
      #   dest is the name of where you want to move them to. 
      #
      # TODO More general pattern for version numbering
      def moves_to_merge(files, dest)
        case files.size
        when 0
          return []
        when 1
          return [] if files.first == dest
          return [{from: files.first, to: dest, version: nil}]
        end
        digits = files.size.to_s.size # How many digits in the version numbers?
        dest = re_version_file(dest, nil) # Remove .V999 from dest, if any
        version_count = 0
        unsorted_moves = files.map {|f| [f, File.timestamp(f)] } # Fetch file versions only once
             .sort_by {|f, timestamp| timestamp} # Sort oldest files first
             .map do |f, timestamp| # Reset versions in order by file date
                    version_count += 1
                    {from: f, version: version_count, to: re_version_file(dest, version_count, digits: digits)}
                  end
             .reject {|spec| spec[:from] == spec[:to]} # Remove any "no-op" moves
        # Calculate dependencies
        unsorted_moves.each.with_index do |move, i|
          move[:index] = i
          move[:depends_on] = []
        end
        unsorted_moves.each.with_index do |move, i|
          unsorted_moves.each do |move2|
            next if move2[:index]==move[:index]
            move[:depends_on] << move2[:index] \
              if move2[:from] == move[:to] || ancestor_directories(move2[:from]).include?(move[:from])
          end
        end
        unsorted_moves.topological_sort do |moves, i|
          move = moves[i]
          move[:depends_on].map {|ix| moves.find_index {|move2| move2[:index]==ix}}.compact
        end
      end

      def re_version_file(f, version, options={})
        digits = options[:digits] || 1
        f =~ /^(.*?)((?:\.V\d+)?)$/ # May already have a .v999 prefix
        version = version ? %Q{.V#{"%0#{digits}d" % version}} : ""
        "#{$1}#{version}"
      end

    end # File class methods

    attr_reader :archive
    attr_reader :tape_path

    attr_accessor :descriptor
    attr_accessor :errors
    attr_accessor :decoded
    attr_accessor :original_tape
    attr_accessor :original_tape_path

    def initialize(options={}, &blk)
      @tape = options[:tape]
      @tape_path = options[:tape_path]
      @size = options[:size]
      @archive = options[:archive]
      clear_errors
      yield(self) if block_given?
    end

    # private_class_method :new
  
    def clear_errors
      @errors = []
    end

    def error(err)
      @errors << err
    end
  
    def open_time
      return nil unless tape_path && File.exists?(tape_path)
      File.atime(tape_path)
    end
  
    def close
      # update_index
    end
  
    def read
      self.class.read(descriptor.tape_path)
    end
  
    def update_index
      return unless @archive
      @archive.update_index(:file=>self)
    end

    def tape
      @tape ||= File.basename(tape_path)
    end
  
    def path
      descriptor.path
    end
    
    def mark(tag_name, tag_value)
      descriptor.set_field(tag_name, tag_value, :user=>true) # Allow only unregistered field names
    end
  
    def updated
      descriptor.updated
    end
  
    def copy_descriptor(to, new_settings={})
      descriptor.copy(to, new_settings)
    end

    def media_codes
      []
    end

    def multi_segment
      false
    end

    def content_start
      0
    end
  end
end