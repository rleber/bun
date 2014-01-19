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

    class << self
      
      @@stdin_cache = nil # Name of the tempfile caching STDIN (if it exists)
      
      # Allows STDIN to be read multiple times
      def read(*args)
        path = args.shift
        path = if path != '-'
          path
        elsif @@stdin_cache
          @@stdin_cache
        else
          cache_stdin
        end
        stop "!File #{path} does not exist" unless File.exists?(path)
        text = ::File.read(path, *args) || ''
        text.force_encoding('ascii-8bit')
      end
      
      # Read STDIN and save it to a tempfile
      def cache_stdin
        tempfile = Tempfile.new('stdin')
        tempfile.write($stdin.read)
        tempfile.close
        @@stdin_cache = tempfile.path
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
          if File.file_grade(path) == :baked
            [nil, File.read(path)]
          elsif File.tape_type(path) == :frozen && !options[:shard]
            files = File::Decoded.open(path, :promote=>true, :expand=>true)
            [files.values.first, files.values.map{|f| f.data}.join ]
          else
            f = File::Decoded.open(path, :promote=>true, :shard=>options[:shard])
            [f, f.data]
          end
        else
          [nil, read(path)]
        end
      end

      def file_for_expression(path, options={})
        if options[:promote]
          if File.file_grade(path) == :baked
            File::Baked.open(path)
          elsif File.tape_type(path) == :frozen && !options[:shard]
            File::Decoded.open(path, :promote=>true).values.first # This is smelly
          else
            File::Decoded.open(path, :promote=>true, :shard=>options[:shard])
          end
        else
          File.open(path)
        end
      end
      
      def baked_data(path, options={})
        _, data = baked_file_and_data(path, options)
        data
      end
      
      def examination(file, exam, options={})
        Bun::File.create_expression(file, exam, promote: options[:promote], shard: options[:shard])
      end
      
      def create_examination(path, analysis, options={})
        examiner = String::Examination.create(analysis, options)
        examiner.attach(:string) { baked_data(path, options) } # Lazy evaluation of file contents
        examiner.attach(:file, self)
        examiner
      end
      protected :create_examination
      
      def create_expression(path, expression, options={})
        expression_options = options.merge(expression: expression, path: path)
        evaluator = Bun::Expression.new(expression_options)
        evaluator.attach(:data) { baked_data(path, options) }
        evaluator.attach(:file) { file_for_expression(path, options={}) }
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
        # TODO But file_grade opens and reads the file, too...
        case grade = file_grade(path)
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
          raise BadFileGrade, "Can't open file of this grade: #{grade.inspect}"
        end
      end
      
      def tape_type(path)
        # return :packed if packed?(path)
        begin
          f = File::Unpacked.open(path, promote: true) 
          f.tape_type
        rescue
          :unknown
        end
      end
      
      def file_grade(path)
        if packed?(path)
          :packed
        elsif binary?(path)
          :baked
        else
          File::Unpacked.build_descriptor_from_file(path).file_grade
        end
      end
      
      def file_grade_level(grade)
        [:packed, :unpacked, :decoded, :baked].index(grade)
      end

      def file_outgrades?(path, level)
        file_grade_level(file_grade(path)) > file_grade_level(level)
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
        case file_grade(path)
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
        case file_grade(path)
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
        case file_grade(path)
        when :baked, :decoded
          File.open(path, options) {|f| f.bake(to)}
        else
          File::Decoded.open(path, options.merge(promote: true)) {|f| f.bake(to)}
        end
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