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

      def import(data)
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
    BITS_PER_WORD = Bun::Word::WIDTH
    BYTES_PER_WORD = bytes_per_word
    BITS_PER_BYTE = bits_per_byte
    PACKED_CHARACTERS_PER_WORD = packed_characters_per_word
    NYBBLES_PER_WORD = (BITS_PER_WORD / 4).ceil
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
      @archive = options[:archive]
      @tape = options[:tape]
      @tape_path = options[:tape_path]
      load options[:data]
    end

    def load(data)
      @data = data
      self.words = self.class.import(@data)
      @data
    end

    def reload
      load @words.export
    end

    def words=(w)
      @words = Bun::Words.new(w)
      if @words.nil?
        @all_characters = @characters = @bytes = @packed_characters = @descriptor = nil
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
      else
        @words.size
      end
    end

    def tape_size
      @words.size
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

    def split_word(w)
      w = w.to_i
      [w>>18, w & 0777777]
    end
    private :split_word

    def get_bcw_at(words, offset)
      split_word(words.at(offset))
    end

    MAXIMUM_CHUNK_SIZE = 320*12 + 100

    def check_bcw(actual_index, actual_offset, expected_index)
      raise File::BadBlockError, "Bad block sequence number #{actual_index} (expected #{expected_index}" \
        unless actual_index == expected_index
      raise File::BadBlockError, "Block #{chunk_number} length out of range (#{chunk_max}(#{'%05o' % chunk_max})" \
        unless actual_offset < MAXIMUM_CHUNK_SIZE
    end

    def get_bcw_from_hex(hex, offset, expected_index)
      bcw_words = Bun::Words.import([hex[offset, NYBBLES_PER_WORD]].pack('H*'))
      actual_index, actual_max = get_bcw_at(bcw_words,0)
      check_bcw actual_index, actual_max, expected_index 
      actual_max
    end

    # This code removes an artifact of the file archiving, once transferred to 8-bit systems
    # See doc/file_format/llink_padding.md for a more extensive discussion
    def deblocked_words
      nybbles_per_word = (Bun::Words.constituent_class.width / 4).ceil
      hex = data.to_hex
      offset = 0
      chunks = []
      while offset < hex.size do
        chunk_max = get_bcw_from_hex(hex, offset, chunks.size+1)
        chunk_size = (chunk_max+1) * NYBBLES_PER_WORD
        chunk = hex[offset, chunk_size]
        chunks << chunk
        offset += chunk_size
        # Check next chunk -- look for extraneous nybble
        if offset < hex.size && chunk_size.odd?
          2.times do |i|
            begin
              get_bcw_from_hex(hex, offset, chunks.size+1)
              break
            rescue File::BadBlockError
              if i==0
                offset += 1
              else
                raise
              end
            end
          end
        end
      end
      # chunk_words = chunks.map{|chunk| Bun::Words.import([chunk].pack('H*'))}
      # chunk_words.each.with_index do |chunk, index|
      #   this_chunk_prefix = chunk.at(0).to_i
      #   this_chunk_index, this_chunk_max = split_word(this_chunk_prefix)
      #   this_preamble_prefix = chunk.at(1).to_i
      #   this_preamble_index, this_preamble_offset = split_word(this_preamble_prefix)
      #   raise BadBlockError,"!Bad chunk (##{index+1}): Chunk index out of sequence (#{'%013o' % this_chunk_prefix})" \
      #     unless this_chunk_index==(index+1)
      #   unless index==chunks.size-1 # Last chunk may be truncated
      #     raise BadBlockError,"!Bad chunk (##{index+1}): Unexpected chunk size (#{'%013o' % this_chunk_prefix})" \
      #       unless this_chunk_max==chunk_max
      #   end
      #   raise BadBlockError,"!Bad chunk (##{index+1}): Preamble index not 1 (#{'%013o' % this_preamble_prefix})" \
      #     unless this_preamble_index==1
      #   raise BadBlockError,"!Bad chunk (##{index+1}): Unexpected preamble length (#{'%013o' % this_preamble_prefix})" \
      #     unless this_preamble_prefix===first_preamble_prefix
      #   first_data_word = chunk.at(this_preamble_offset)
      #   if index > 0
      #     removed_words = chunk_words[index].slice!(0,this_preamble_offset)
      #     removed_words.each.with_index do |w, i|
      #       debug "#{i}: #{'%013o' % w}"
      #     end
      #     debug "Data: #{'%013o' % chunk_words[index].at(0)}"
      #     raise BadBlockError,"!Unexpected result of truncation" unless first_data_word == chunk_words[index].at(0)
      #   end
      # end
      Bun::Words.import([chunks.join].pack('H*'))
    end

    def deblocked
      res = self.dup
      res.load(deblocked_words.export)
      res
    end
  end
end