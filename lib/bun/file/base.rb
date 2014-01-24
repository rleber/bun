#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

require 'lib/bun/file/descriptor'
require 'lib/string'
require 'yaml'
require 'date'
require 'tmpdir'

module Bun

  class File < ::File
    
    class BadFileGrade < RuntimeError; end
    class BadBlockError < RuntimeError; end
    class ReadError < ArgumentError; end

    class << self
      
      @@stdin_cache = nil  # Content of STDIN (we cache it, to allow rereading)
      @@last_read = nil    # Name of the last file read, except STDIN (we save it, to avoid rereading)
      @@last_content = nil # Content of the last file read (except STDIN)
      
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
      
      def packed?(path)
        return false if nonpacked?(path)
        if path.to_s =~ /^$|^-$|ar\d{3}\.\d{4}$/ # nil, '', '-' (all STDIN) or '...ar999.9999'
          begin
            File::Packed.open(path, force: true)
          rescue => e
            false
          end
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
          raise BadFileGrade, "Can't open file of this format: #{fmt.inspect}"
        end
      end
      
      def type(path)
        # return :packed if packed?(path)
        begin
          f = File::Unpacked.open(path, promote: true) 
          f.type
        rescue
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
        descr = File::Unpacked.build_descriptor_from_file(file) rescue nil
        time = descr && descr.timestamp
        time || Time.now
      end
      
      # Convert from packed format to unpacked (i.e. YAML)
      def unpack(path, to, options={})
        case format(path)
        when :packed
          open(path) do |f|
            cvt = f.unpack
            cvt.descriptor.tape = options[:tape] if options[:tape]
            cvt.descriptor.merge!(:unpack_time=>Time.now, :unpacked_by=>Bun.expanded_version)
            cvt.write(to)
          end
        else
          Shell.new.cp(path, to)
        end
      end

      def decode(path, to, options={}, &blk)
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
          File.open(path, options) {|f| f.bake(to, scrub: scrub)}
        else
          File::Decoded.open(path, options.merge(promote: true)) {|f| f.bake(to, scrub: scrub)}
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
    end
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
  end
end