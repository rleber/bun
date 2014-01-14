#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

require 'date'

module Bun

  class Data
    class << self

      EOF_MARKER = 0x00000f000 # Octal 000000170000 or 0b000000000000000000001111000000000000

      def eof_marker
        EOF_MARKER
      end
  
      def characters_per_word
        Bun::Word.character.count
      end

      def bytes_per_word
        Bun::Word.byte.count
      end

      def bits_per_byte
        Bun::Word.byte.width
      end

      def packed_characters_per_word
        Bun::Word.packed_character.count
      end

      def decode(data)
        Bun::Words.import(data)
      end

      # Convert an eight-character Bun date "mm/dd/yy" to a Ruby Date
      def date(date)
        Date.strptime(date,"%m/%d/%y")
      end

      # Convert a Bun timestamp to the time of day in hours (24 hour clock)
      # Returns a three item array: hour, minutes, seconds (with embedded fractional seconds)
      TIME_SUM = 1620000 # additive offset for converting Bun times
      TIME_DIV = 64000.0 # division factor for converting Bun ticks to seconds
      def time_of_day(timestamp)
        timestamp = timestamp.integer.value
        seconds = (timestamp + TIME_SUM) / TIME_DIV
        minutes, seconds = seconds.divmod(60.0)
        hours, minutes = minutes.divmod(60.0)
        [hours, minutes, seconds.to_int]
      end

      # Convert a Bun date and time into a Ruby Time
      def time(date, timestamp)
        hours, minutes, seconds = time_of_day(timestamp)
        seconds, frac = seconds.divmod(1.0)
        micro_seconds = (frac*1000000).to_i
        date = self.date(date)
        Time.local(date.year, date.month, date.day, hours, minutes, seconds, micro_seconds)
      end
  
      def content_offset(words)
        words.at(1).half_word(1).value rescue 0
      end
    end

    CHARACTERS_PER_WORD = characters_per_word
    BYTES_PER_WORD = bytes_per_word
    BITS_PER_BYTE = bits_per_byte
    PACKED_CHARACTERS_PER_WORD = packed_characters_per_word
    ARCHIVE_NAME_POSITION = 7 # words
    SPECIFICATION_POSITION = 11 # words
    DESCRIPTION_PATTERN = /\s+(.*)/

    attr_reader :all_characters
    attr_reader :all_packed_characters
    attr_reader :characters
    attr_reader :bytes
    attr_reader :file_content
    attr_reader :packed_characters
    attr_reader :words
    attr_reader :data
    attr_reader :descriptor
    attr_reader :archive
    attr_reader :tape
    attr_reader :tape_path

    def initialize(options={})
      @data = options[:data]
      @archive = options[:archive]
      @tape = options[:tape]
      @tape_path = options[:tape_path]
      @words = self.class.decode(data)
      if @words.nil?
        @all_characters = @characters = @packed_characters = @descriptor = nil
      else
        @descriptor = Bun::File::Descriptor::Packed.new(self)
        @all_characters = LazyArray.new(@words.size*characters_per_word) do |n|
          @words.characters.at(n)
        end
        @all_packed_characters = LazyArray.new(@words.size*packed_characters_per_word) do |n|
          @words.packed_characters.at(n)
        end
        @file_content = LazyArray.new(size-content_offset) do |n|
          # TODO is this check vs. size necessary? is it correct?
          n < self.size ? word(content_offset+n) : nil
        end
        @characters = LazyArray.new(@file_content.size*characters_per_word) do |n|
          @words.characters.at(n + content_offset*characters_per_word)
        end
        @bytes = LazyArray.new(@file_content.size*bytes_per_word) do |n|
          @words.bytes.at(n + content_offset*bytes_per_word)
        end
        @packed_characters = LazyArray.new(@file_content.size*packed_characters_per_word) do |n|
          @words.characters.at(n + content_offset*packed_characters_per_word)
        end
      end
    end

    def word(n)
      @words.at(n)
    end

    def clear
      self.words = nil
    end

    def content
      @file_content
    end

    def delimited_string(offset, options={})
      delimiter = options[:delimiter] || "\0"
      start = offset
      if options[:all]
        chars = all_characters
        chars_per_word = CHARACTERS_PER_WORD
      elsif options[:packed]
        chars = packed_characters
        chars_per_word = PACKED_CHARACTERS_PER_WORD
      else
        chars = characters
        chars_per_word = CHARACTERS_PER_WORD
      end
      size = chars.size
      offset *= chars_per_word if options[:word_offset]
      string = ""
      loop do
        break if offset >= size
        word_index, ch_index = offset.divmod(chars_per_word)
        word = word(word_index)
        break if !word || (word == self.class.eof_marker && !options[:all])
        char = chars.at(offset)
        break if char == delimiter
        string << char
        offset += 1
      end
      string
    end

    def content_offset
      self.class.content_offset(words)
    end

    def header_size
      content_offset
    end

    def size(options={})
      # TODO Should :eof be the default? (Is there ever a meaningful eof marker in frozen files?)
      if options[:eof]
        eof_tape = nil
        words.each_with_index do |word, index|
          if word.value == self.class.eof_marker
            eof_tape = index
            break
          end
        end
        eof_tape || size
      elsif options[:all]
        @words.size
      else
        @size || tape_size
      end
    end

    def tape_size
      ((word(0).half_word(1))+1).value rescue 0
    end
    
    def frozen_tape_size
      word(content_offset).value + content_offset
    end

    def date(tape)
      date_string = content[tape,2].characters.join
      self.class.date(date_string)
    end

    def time_of_day(tape)
      self.class.time_of_day content.at(tape)
    end

    def time(date_tape, time_tape)
      self.class.time date(date_tape), time_of_day(time_tape)
    end

    def catalog_time
      archive && archive.catalog_time(descriptor.tape)
    end

    def characters_per_word
      self.class.characters_per_word
    end

    def packed_characters_per_word
      self.class.packed_characters_per_word
    end

    def bytes_per_word
      self.class.bytes_per_word
    end

    def frozen?
      File::Frozen::Descriptor.frozen?(self)
    end

    def tape_type
      if frozen?
        :frozen
      elsif word(content_offset).characters.join == 'huff'
        :huffman
      else
        :text
      end
    end
    
    def eof_marker
      self.class.eof_marker
    end
  end
end