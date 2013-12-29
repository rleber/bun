#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

require 'lib/bun/file/descriptor'
require 'yaml'
require 'date'

module Bun

  class File < ::File
    class InvalidFileCheck < ArgumentError; end

    class << self
      
      def preread(path)
        return $stdin_tempfile if $stdin_tempfile
        if path == '-'
          tempfile = Tempfile.new('stdin')
          tempfile.write($stdin.read)
          tempfile.close
          $stdin_tempfile = tempfile.path
        else
          path
        end
      end
      
      def read(*args)
        path = preread(args.first)
        args[0] = path
        ::File.read(*args)
      end
      
      # attr_accessor :stdin_buffer
      # 
      #  def read(*args)
      #    original_args = args.dup
      #    options = {}
      #    if args.last.is_a?(Hash)
      #      options = args.pop
      #    end
      #    raise "Missing path" if args.size == 0
      #    encoding = options[:encoding] || 'ascii-8bit'
      #    path = args.first
      #    res = if path == '-'
      #      stdin_buffer ||= ''
      #      if args.size >=2
      #        len = args[1]
      #        if len > stdin_buffer.size
      #          data = $stdin.read(len-stdin_buffer.size).force_encoding(encoding)
      #          stdin_buffer += data
      #        end
      #        stdin_buffer[0,len]
      #      else
      #        stdin_buffer + $stdin.read.force_encoding(encoding)
      #      end
      #    else
      #      debug "About to do File.read: args: #{args.inspect}"
      #      ::File.read(*args)
      #    end
      #    debug "args: #{original_args.inspect} => #{res.inspect}"
      #    res
      #  end
 
      def relative_path(*f)
        options = {}
        if f.last.is_a?(Hash)
          options = f.pop
        end
        relative_to = options[:relative_to] || ENV['HOME']
        File.expand_path(File.join(*f), relative_to).sub(/^#{Regexp.escape(relative_to)}\//,'')
      end

      VALID_CONTROL_CHARACTERS = '\n\r\x8\x9\xb\xc' # \x8 is a backspace, \x9 is a tab, \xb is a VT, \xc is a form-feed
      VALID_CONTROL_CHARACTER_STRING = eval("\"#{VALID_CONTROL_CHARACTERS}\"")
      VALID_CONTROL_CHARACTER_REGEXP = /[#{VALID_CONTROL_CHARACTERS}]/
      INVALID_CHARACTER_REGEXP = /(?!(?>#{VALID_CONTROL_CHARACTER_REGEXP}))[[:cntrl:]]/
      VALID_CHARACTER_REGEXP = /(?!(?>#{INVALID_CHARACTER_REGEXP}))./

      def control_character_counts(text)
        control_characters = Hash.new(0)
        ["\t","\b","\f","\v",File.invalid_character_regexp].each do |pat|
          text.scan(pat) {|ch| control_characters[ch] += 1 }
        end
        control_characters
      end

      def valid_control_character_regexp
        VALID_CONTROL_CHARACTER_REGEXP
      end

      def invalid_character_regexp
        INVALID_CHARACTER_REGEXP
      end

      def valid_character_regexp
        VALID_CHARACTER_REGEXP
      end
  
      def clean?(text)
        text.force_encoding('ascii-8bit') !~ INVALID_CHARACTER_REGEXP
      end

      CHECK_TESTS = {
        clean: {
          options: [:clean, :dirty],
          description: "File contains special characters",
          test: lambda {|text| File.clean?(text) ? :clean : :dirty }
        }
      }
      
      def check_tests
        CHECK_TESTS
      end
      
      def check(path, test)
        spec = check_tests[test.to_sym]
        raise InvalidFileCheck, "!Invalid test: #{test.inspect}" unless spec
        content = read(path)
        test_result = spec[:test].call(content)
        ix = spec[:options].index(test_result) || spec[:options].size
        {code: ix, description: test_result}
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
      
      def file_type(path)
        return :packed if packed?(path)
        begin
          f = File::Unpacked.open(path)
          f.file_type
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
  
    def updated
      descriptor.updated
    end
  
    def copy_descriptor(to, new_settings={})
      descriptor.copy(to, new_settings)
    end
  end
end