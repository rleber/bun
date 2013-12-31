#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

require 'lib/bun/file/descriptor'
require 'lib/string'
require 'yaml'
require 'date'

module Bun

  class File < ::File

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
        ::File.read(path, *args)
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
      
      def examination(path, analysis)
        read(path).examination(analysis)
      end
  
      def descriptor(options={})
        Header.new(options).descriptor
      end
      
      def packed?(path)
        prefix = File.read(path, 3)
        prefix != '---' # YAML prefix; one of the unpacked formats
      end
      
      def open(path, options={}, &blk)
        if packed?(path)
          File::Packed.open(path, options, &blk)
        else
          File::Unpacked.open(path, options, &blk)
        end
      end
      
      def tape_type(path)
        return :packed if packed?(path)
        begin
          f = File::Unpacked.open(path)
          f.tape_type
        rescue
          :unknown
        end
      end
      
      def descriptor(path, options={})
        open(path) {|f| f.descriptor }
      rescue Bun::File::UnknownFileType =>e 
        nil
      rescue Errno::ENOENT => e
        return nil if options[:allow]
        stop "!File #{path} does not exist" if options[:graceful]
        raise
      end
      
      # Convert from packed format to unpacked (i.e. YAML)
      def unpack(path, to, options={})
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