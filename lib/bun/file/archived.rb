#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

require 'date'

module Bun

  class File < ::File
    class Archived < Bun::File
      class << self

        EOF_MARKER = 0x00000f000 # Octal 000000170000 or 0b000000000000000000001111000000000000
  
        def eof_marker
          EOF_MARKER
        end
    
        def characters_per_word
          Bun::Word.character.count
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
    
        def descriptor(options={})
          Header.new(options).descriptor
        end
    
        def frozen?(file_name)
          raise "File #{file_name} doesn't exist" unless File.exists?(file_name)
          new(:hoard_path=>file_name).frozen?
        end
    
        def create(options={}, &blk)
          preamble = nil
          if options[:type]
            ftype = options[:type]
          else
            preamble = get_preamble(options)
            ftype = preamble.file_type
          end
          klass = const_get(ftype.to_s.sub(/^./){|m| m.upcase}) unless ftype.is_a?(Class)
          if options[:header]
            if ftype == :frozen
              limit = Frozen.send(:new, :words=>preamble.words, :header=>true).header_size
            else
              limit = preamble.header_size
            end
          else
            limit = nil
          end
          f = klass.send(:new, options.merge(:n=>limit))
          res = if block_given?
            begin
              yield(f)
            rescue => e
              raise "!Raised error in yield: #{e}"
            ensure
              f.close
            end
          else
            f
          end
        end

        def open(fname, options={}, &blk)
          create(options.merge(:hoard_path=>fname), &blk)
        end
      
        def read(fname, size=nil)
          ::File.open(fname, "r:ascii-8bit") {|f| f.read(size) }
        end
    
        def header(options={}, &blk)
          create(options.merge(:header=>true), &blk)
        end
    
        INITIAL_FETCH_SIZE = 30
        def get_preamble(options)
          initial_fetch = get_words(INITIAL_FETCH_SIZE, options)
          preamble_size = content_offset(initial_fetch)
          fetch_size = preamble_size + File::Frozen::Descriptor.offset+ File::Frozen::Descriptor.size
          full_fetch = fetch_size > INITIAL_FETCH_SIZE ? get_words(fetch_size, options) : initial_fetch
          File::Raw.send(:new, :words=>full_fetch)
        end
    
        def get_words(n, options)
          if options[:hoard_path]
            Bun::Words.read(options[:hoard_path], :n=>n)
          elsif options[:data]
            if n.nil?
              decode(options[:data])
            else
              bytes = (Bun::Word.width*n + 8 - 1).div(8)
              # TODO Optimize the following:
              decode(options[:data][0,bytes])
            end
          else
            if n.nil?
              options[:words]
            else
              # TODO Optimize the following:
              options[:words][0,n]
            end
          end
        end
    
        def content_offset(words)
          words.at(1).half_word(1).value
        end
      end
  
      CHARACTERS_PER_WORD = characters_per_word
      PACKED_CHARACTERS_PER_WORD = packed_characters_per_word
      ARCHIVE_NAME_POSITION = 7 # words
      SPECIFICATION_POSITION = 11 # words
      DESCRIPTION_PATTERN = /\s+(.*)/
  
      attr_reader :all_characters
      attr_reader :all_packed_characters
      attr_reader :characters
      attr_reader :file_content
      attr_reader :packed_characters
      attr_reader :words
  
      def initialize(options={}, &blk)
        @header = options[:header]
        self.words = self.class.get_words(options[:limit], options)
        super
      end
      
      def header?
        @header
      end
  
      def words=(words)
        if words.nil?
          @words = @all_characters = @characters = @packed_characters = @descriptor = nil
        else
          @words = words
          @descriptor = Descriptor::Archived.new(self)
          @all_characters = LazyArray.new(words.size*characters_per_word) do |n|
            @words.characters.at(n)
          end
          @all_packed_characters = LazyArray.new(words.size*packed_characters_per_word) do |n|
            @words.packed_characters.at(n)
          end
          unless header?
            @file_content = LazyArray.new(size-content_offset) do |n|
              # TODO is this check vs. size necessary? is it correct?
              n < self.size ? word(content_offset+n) : nil
            end
            @characters = LazyArray.new(@file_content.size*characters_per_word) do |n|
              @words.characters.at(n + content_offset*characters_per_word)
            end
            @packed_characters = LazyArray.new(@file_content.size*packed_characters_per_word) do |n|
              @words.characters.at(n + content_offset*packed_characters_per_word)
            end
          end
        end
        words
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
          eof_hoard = nil
          words.each_with_index do |word, index|
            if word.value == self.class.eof_marker
              eof_hoard = index
              break
            end
          end
          eof_hoard || size
        elsif options[:all]
          @words.size
        else
          @size || file_size
        end
      end
  
      def file_size
        res = (word(0).half_word(1))+1
        res = res.value unless res.is_a?(Fixnum)
        res
      end

      def date(hoard)
        date_string = content[hoard,2].characters.join
        self.class.date(date_string)
      end
  
      def time_of_day(hoard)
        self.class.time_of_day content.at(hoard)
      end
  
      def time(date_hoard, time_hoard)
        self.class.time date(date_hoard), time_of_day(time_hoard)
      end
  
      def catalog_time
        archive && archive.catalog_time(hoard)
      end

      def characters_per_word
        self.class.characters_per_word
      end
  
      def packed_characters_per_word
        self.class.packed_characters_per_word
      end
  
      def frozen?
        File::Frozen::Descriptor.frozen?(self)
      end
  
      def file_type
        return :frozen if frozen?
        return :huffman if word(content_offset).characters.join == 'huff'
        return :text
      end
    end
  end
end