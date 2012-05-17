#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

require 'lib/bun/file/descriptor'
require 'date'

module Bun

  class File < ::File
    class << self

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
        text !~ INVALID_CHARACTER_REGEXP
      end
  
      def descriptor(options={})
        Header.new(options).descriptor
      end
    end
    attr_reader :archive
    attr_reader :location_path

    attr_accessor :descriptor
    attr_accessor :errors
    attr_accessor :extracted
    attr_accessor :original_location
    attr_accessor :original_location_path

    def initialize(options={}, &blk)
      @location = options[:location]
      @location_path = options[:location_path]
      @size = options[:size]
      @archive = options[:archive]
      clear_errors
      yield(self) if block_given?
    end

    private_class_method :new
  
    def clear_errors
      @errors = []
    end

    def error(err)
      @errors << err
    end
  
    def open_time
      return nil unless location_path && File.exists?(location_path)
      File.atime(location_path)
    end
  
    def close
      update_index
    end
  
    def read
      self.class.read(location_path)
    end
  
    def update_index
      return unless @archive
      @archive.update_index(:file=>self)
    end

    def location
      @location ||= File.basename(location_path)
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