#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

require 'date'

module Bun

  class Data
    include CacheableMethods
    class BadTime < RuntimeError; end

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
      rescue ArgumentError => e 
        raise unless e.to_s =~ /invalid date/
        raise BadTime, e.to_s
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
      def internal_time(date, timestamp)
        hours, minutes, seconds = time_of_day(timestamp)
        seconds, frac = seconds.divmod(1.0)
        micro_seconds = (frac*1000000).to_i
        date = self.date(date)
        begin        
          Time.local(date.year, date.month, date.day, hours, minutes, seconds, micro_seconds)
        rescue ArgumentError => e
          raise unless e.to_s =~ /argument out of range/
          raise BadTime, e.to_s
        end
      end
  
      def content_offset(words)
        words.at(1).half_word(1).value rescue 0
      end
    end

    WORDS_PER_SECTOR = 64
    SECTOR_CHECKSUM_OFFSET = WORDS_PER_SECTOR-1
    CHARACTERS_PER_WORD = characters_per_word
    BITS_PER_WORD = Bun::Word::WIDTH
    BYTES_PER_WORD = bytes_per_word
    BITS_PER_BYTE = bits_per_byte
    PACKED_CHARACTERS_PER_WORD = packed_characters_per_word
    NYBBLES_PER_WORD = (BITS_PER_WORD / 4).ceil
    ARCHIVE_NAME_POSITION = 7 # words
    SPECIFICATION_POSITION = 11 # words
    DESCRIPTION_PATTERN = /\s+(.*)/
    EXECUTABLE_MODULE_CATALOG_OFFSET = 2
    EXECUTABLE_MODULE_CATALOG_SIZE = 4

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
      @block_count = nil
      @block_padding_repairs = 0
      @first_block_size = nil
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
        # TODO Are there really examples of eof markers?
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
          # TODO Are there really examples of eof markers?
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

    def internal_time(date_tape, time_tape)
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

    def type
      if frozen?
        :frozen
      elsif (word(content_offset).characters || ['']).join == 'huff'
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

    MAXIMUM_BLOCK_SIZE = 320*12 + 100

    def location(at)
      "#{at}(0#{'%o' % at})"
    end

    def minidump(at, width)
      word, nybble = at.divmod(NYBBLES_PER_WORD)
      $stderr.puts "File dump at nybble #{location(at)} (word #{location(word)}, nybble #{nybble}):"
      (([0,word-width].max)..([words.size-1,word+width].min)).each do |loc|
        flag = loc==word ? '<=' : ' '
        $stderr.puts "#{location(loc)}: #{'%013o' % words.at(loc)} #{flag}"
      end
    end

    def bad_bcw(offset, msg, options={})
      minidump(offset, 010) unless options[:quiet] || options[:fix]
      raise File::BadBlockError, msg
    end

    def get_bcw_from_hex(hex, offset, expected_index, options={})
      bcw_words = Bun::Words.import([hex[offset, NYBBLES_PER_WORD]].pack('H*'))
      return nil if bcw_words.first == 0
      actual_index, actual_max = get_bcw_at(bcw_words,0)
      unless actual_index == expected_index
        bad_bcw offset, "Bad block sequence number at nybble #{location(offset)}: " + 
          "#{actual_index} (expected #{expected_index})", 
          quiet: options[:quiet], fix: options[:fix]
      end
      unless actual_max < MAXIMUM_BLOCK_SIZE
        bad_bcw offset, "Block #{actual_index} length out of range at nybble #{location(offset)}: " + 
          "#{actual_max}(#{'%05o' % actual_max}", 
          quiet: options[:quiet], fix: options[:fix]
      end
      actual_max
    end

    # This code removes an artifact of the file archiving, once transferred to 8-bit systems
    # See doc/file_format/llink_padding.md for a more extensive discussion
    def block_padding_repaired_words(options={})
      nybbles_per_word = (Bun::Words.constituent_class.width / 4).ceil
      hex = data.to_hex
      offset = 0
      blocks = []
      @block_count = 0
      @block_padding_repairs = 0
      @block_maximums = []
      while offset < hex.size do
        block_max = begin
          get_bcw_from_hex(hex, offset, blocks.size+1, fix: options[:fix])
        rescue File::BadBlockError => e
          if options[:fix]
            warn "!#{e}: File truncated" unless options[:quiet]
            break
          end
          raise
        end
        break unless block_max
        @block_maximums << block_max
        block_size = (block_max+1) * NYBBLES_PER_WORD
        unless @first_block_size
          @first_block_size = block_max + 1
        end
        @block_count += 1
        block = hex[offset, block_size]
        blocks << block
        offset += block_size
        # Check next block -- look for extraneous nybble
        if offset < hex.size && block_size.odd?
          2.times do |i|
            begin
              get_bcw_from_hex(hex, offset, blocks.size+1, quiet: true)
              @block_padding_repairs += 1 if i>0 # Had to go to the second try
              break
            rescue File::BadBlockError
              if i==0
                offset += 1
              else
                get_bcw_from_hex(hex, offset, blocks.size+1)
              end
            end
          end
        end
      end
      @block_padding_repaired_words = Bun::Words.import([blocks.join].pack('H*'))
    end
    cache :block_padding_repaired_words
    
    def with_block_padding_repaired(options={})
      res = self.dup
      w = block_padding_repaired_words(fix: options[:fix])
      s = w.export
      repairs = self.block_padding_repairs
      res.load(s)
      res.block_padding_repairs = repairs # Necessary, because load will reset this to zero
      res
    end

    def block_count
      unless @block_count
        _ = block_padding_repaired_words
      end
      @block_count
    end

    def block_padding_repairs=(value)
      @block_padding_repairs = value
    end

    def block_padding_repairs
      unless @block_padding_repairs
        _ = block_padding_repaired_words
      end
      @block_padding_repairs
    end

    def first_block_size
      unless @first_block_size
        _ = block_padding_repaired_words
      end
      @first_block_size
    end

    def block_maximums
      unless @block_maximums
        _ = block_padding_repaired_words
      end
      @block_maximums
    end

    def block_content_sizes
      block_maximums.map {|bmax| bmax + 1 - content_offset }
    end

    def sectors
      block_content_sizes.map{|content_size| content_size.div(WORDS_PER_SECTOR) }.sum
    end

    # Extract module names from an executable (Q* format) file
    # Also serves as a test that a file is a Q* executable
    # See doc/file_formats folder for relevant documentation (files l-code.c, qstar.c and qstar-layout.pdf)
    # Many thanks to Alan Bowler of Thinkage Ltd. (www.thinkage.ca) for documentation and assistance
    def executable_module_names
      catalog_header = content[0]
      first_space_block = catalog_header.half_word[0].to_i
      return nil unless first_space_block == 1
      next_catalog_block = catalog_header.half_word[1].to_i
      sectors = self.sectors
      return nil unless next_catalog_block < sectors
      available_space_block_offset = WORDS_PER_SECTOR
      available_space_block_header = content[available_space_block_offset]
      return nil unless available_space_block_header.half_word[0].to_i == 0
      next_available_spack_block = available_space_block_header.half_word[1].to_i
      return nil unless next_available_spack_block < sectors
      return nil unless compare_executable_checksum(0)
      return nil unless compare_executable_checksum(available_space_block_offset)
      modules = []
      (EXECUTABLE_MODULE_CATALOG_OFFSET...(WORDS_PER_SECTOR-EXECUTABLE_MODULE_CATALOG_SIZE)).step(EXECUTABLE_MODULE_CATALOG_SIZE) do |i|
        module_name = content[i].bcd_string
        flag_word = content[i+1]
        type, blocks, first_block = self.class.split_executable_module_flag(flag_word)
        end_block = first_block + blocks
        return nil if type > 3
        return nil if end_block > sectors
        modules << module_name if blocks > 0
      end
      modules
    end

  def executable?
    executable_module_names
  end

  def self.split_executable_module_flag(word)
    [(word.byte[0] >> 3).to_i, (word.half_word[0] & 07777).to_i, word.half_word[1].to_i]
  end

  def compare_executable_checksum(offset)
    start_offset = content_offset + offset
    calculated_checksum = executable_checksum(start_offset...start_offset+SECTOR_CHECKSUM_OFFSET)
    stored_checksum = content[offset+SECTOR_CHECKSUM_OFFSET]
    return calculated_checksum == stored_checksum
  end

    def executable_checksum(range)
      sum = 0
      carry = 0
      words[range].each do |word|
        sum += carry + word.to_i
        carry, sum = sum.divmod(1<<36)
      end
      sum += carry
      sum = sum % (1<<36)
      sum
    end
  end
end