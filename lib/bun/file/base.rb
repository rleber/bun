#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

require 'lib/bun/file/descriptor'
require 'lib/string'
require 'yaml'
require 'date'

module Bun

  class File < ::File
    
    class BadFileGrade < RuntimeError; end

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

      # def control_character_counts(path)
      #   Bun.readfile(path).control_character_counts
      # end
      
      def baked_file_and_data(path, options={})
        if options[:promote]
          if File.file_grade(path) == :baked
            [nil, File.read(path)]
          else
            f = File::Decoded.open(path, :promote=>true)
            [f, f.data]
          end
        else
          [nil, read(path)]
        end
      end
      
      def baked_data(path, options={})
        _, data = baked_file_and_data(path, options)
        data
      end
      
      def examination(file, options={})
        if options[:exam]
          examination = Bun::File.create_examination(file, options[:exam], promote: options[:promote])
          # TODO Change this to range
          examination.minimum = options[:min] if examination.respond_to?(:minimum)
          examination.case_insensitive = options[:case] if examination.respond_to?(:case_insensitive)
          {
            result: examination,
            code:   examination.code,
            tag:    options[:tag] || "exam:#{options[:exam]}",
          }
        elsif options[:field]
          value = File.open(file) do |f|
            value = f.descriptor[options[:field]] || nil rescue nil
          end
          {
            result: value,
            tag: options[:field]
          }
        elsif options[:formula]
          # TODO allow other parameters to the formula, from the command line
          formula = Bun::File.create_formula(file, options[:formula], promote: options[:promote])
          {
            # TODO Use .value?
            result: formula.to_s,
            tag:    options[:tag],
          }
        elsif options[:match]
          regexp = Regexp.new(options[:match])
          if options[:case]
            regexp = Regexp.new(options[:match], Regexp::IGNORECASE)
          else
            regexp = Regexp.new(options[:match])
          end
          res = baked_data(file, options) =~ regexp
          { result: res, code: res.nil? ? 1 : 0 }
        elsif options[:text]
          { result: baked_data(file, promote: true)||'', code: 0 }
        end
      end
      
      def create_examination(path, analysis, options={})
        baked_data(path, options).examination(analysis, file: path)
      end
      protected :create_examination
      
      def create_formula(path, expression, options={})
        file, data = baked_file_and_data(path, options)
        data.formula(options.merge(
                            expression: expression,
                            file: file,
                            path: path))
      end
      protected :create_formula
  
      def binary?(path)
        prefix = File.read(path, 4)
        prefix != "---\n" # YAML prefix; one of the unpacked formats
      end
      
      def unpacked?(path)
        prefix = File.read(path, 21)
        prefix != "---\n:identifier: Bun\n" # YAML prefix with identifier
      end
      
      def packed?(path)
        return false if !unpacked?(path)
        if path.to_s =~ /^$|^-$|ar\d{3}\.\d{4}$/ # nil, '', '-' (all STDIN) or '...ar999.9999'
          begin
            File::Packed.open(path, force: true)
          rescue 
            false
          end
        else
          false
        end
      end
      
      def open(path, options={}, &blk)
        # TODO But file_grade opens and reads the file, too...
        case file_grade(path)
        when :packed
          File::Packed.open(path, options, &blk)
        when :unpacked
          File::Unpacked.open(path, options, &blk)
        when :decoded
          File::Decoded.open(path, options, &blk)
        else
          # TODO Why not?
          raise BadFileGrade, "Can't open baked file"
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
          f = File::Unpacked.open(path, :force=>true)
          f.descriptor.file_grade
        end
      end
      
      def file_grade_level(grade)
        [:packed, :unpacked, :decoded, :baked].index(grade)
      end
      
      def descriptor(path, options={})
        # TODO This is smelly (but necessary, in case the file was opened with :force)
        # bun describe <packed file> fails right here
        open(path, :force=>true) {|f| f.descriptor }
      rescue Errno::ENOENT => e
        return nil if options[:allow]
        raise
      end
      
      # Convert from packed format to unpacked (i.e. YAML)
      # TODO: move to File::Packed
      def unpack(path, to, options={})
        # debug "path: #{path}, to: #{to}, options: #{options.inspect}\n  caller: #{caller.first}"
        return unless packed?(path)
        open(path) do |f|
          cvt = f.unpack
          cvt.descriptor.tape = options[:tape] if options[:tape]
          cvt.descriptor.merge!(:unpack_time=>Time.now, :unpacked_by=>Bun.expanded_version)
          cvt.write(to)
        end
      end
      
      def expand_path(path, relative_to=nil)
        path == '-' ? path : super(path, relative_to)
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
      self.class.read(tape_path)
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
      descriptor.set_field(tag_name, tag_value)
    end
  
    def updated
      descriptor.updated
    end
  
    def copy_descriptor(to, new_settings={})
      descriptor.copy(to, new_settings)
    end
  end
end