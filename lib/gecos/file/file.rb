require 'gecos/file/descriptor'

class GECOS
  # TODO What would happen if GECOS::File subclassed File?
  class File
    # TODO Defroster is a subclass
    
    class << self

      EOF_MARKER = 0x00000f000 # Octal 000000170000 or 0b000000000000000000001111000000000000
    
      def eof_marker
        EOF_MARKER
      end
      
      def characters_per_word
        GECOS::Word.character.count
      end

      def packed_characters_per_word
        GECOS::Word.packed_character.count
      end

      def decode(data)
        GECOS::Words.import(data)
      end

      def open(fname, &blk)
        new(:file=>fname, &blk)
      end

      # Convert an eight-character GECOS date "mm/dd/yy" to a Ruby Date
      def date(date)
        Date.strptime(date,"%m/%d/%y")
      end

      # Convert a GECOS timestamp to the time of day in hours (24 hour clock)
      # Returns a three item array: hour, minutes, seconds (with embedded fractional seconds)
      TIME_SUM = 1620000 # additive offset for converting GECOS times
      TIME_DIV = 64000.0 # division factor for converting GECOS ticks to seconds
      def time_of_day(timestamp)
        timestamp = timestamp.integer.value
        seconds = (timestamp + TIME_SUM) / TIME_DIV
        minutes, seconds = seconds.divmod(60.0)
        hours, minutes = minutes.divmod(60.0)
        [hours, minutes, seconds]
      end

      # Convert a GECOS date and time into a Ruby Time
      def time(date, timestamp)
        hours, minutes, seconds = time_of_day(timestamp)
        seconds, frac = seconds.divmod(1.0)
        micro_seconds = (frac*1000000).to_i
        date = self.date(date)
        Time.local(date.year, date.month, date.day, hours, minutes, seconds, micro_seconds)
      end
    
      def relative_path(*f)
        ::File.expand_path(::File.join(*f), ENV['HOME']).sub(/^#{Regexp.escape(ENV['HOME'])}\//,'')
      end

      VALID_CONTROL_CHARACTERS = '\r\t\n\b'
      VALID_CONTROL_CHARACTER_STRING = eval("\"#{VALID_CONTROL_CHARACTERS}\"")
      VALID_CONTROL_CHARACTER_REGEXP = /[#{VALID_CONTROL_CHARACTERS}]/
      INVALID_CHARACTER_REGEXP = /(?!(?>#{VALID_CONTROL_CHARACTER_REGEXP}))[[:cntrl:]]/
      VALID_CHARACTER_REGEXP = /(?!(?>#{INVALID_CHARACTER_REGEXP}))./

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
      
      def frozen?(file_name)
        raise "File #{file_name} doesn't exist" unless ::File.exists?(file_name)
        new(:file=>file_name).frozen?
      end
    end
    
    CHARACTERS_PER_WORD = characters_per_word
    PACKED_CHARACTERS_PER_WORD = packed_characters_per_word
    ARCHIVE_NAME_POSITION = 7 # words
    SPECIFICATION_POSITION = 11 # words
    DESCRIPTION_PATTERN = /\s+(.*)/
    
    attr_reader :words, :descriptor, :all_characters, :characters, :all_packed_characters, :packed_characters
    
    def initialize(options={}, &blk)
      file = options[:file]
      data = options[:data]
      words = options[:words]
      if file
        words = GECOS::Words.read(file)
      elsif data
        words = self.class.decode(data)
      end
      self.words = words
      yield(self) if block_given?
    end
    
    def words=(words)
      if words.nil?
        @words = @all_characters = @characters = @packed_characters = @descriptor = nil
      else
        @words = words
        @descriptor = Descriptor.new(self)
        @all_characters = LazyArray.new(words.size*characters_per_word) do |n|
          @words.characters[n]
        end
        @all_packed_characters = LazyArray.new(words.size*packed_characters_per_word) do |n|
          @words.packed_characters[n]
        end
        @file_content = LazyArray.new(size-content_offset) do |n|
          n < self.size ? @words[content_offset+n] : nil
        end
        @characters = LazyArray.new(@file_content.size*characters_per_word) do |n|
          @words.characters[n + content_offset*characters_per_word]
        end
        @packed_characters = LazyArray.new(@file_content.size*packed_characters_per_word) do |n|
          @words.characters[n + content_offset*packed_characters_per_word]
        end
      end
      words
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
        word = words[word_index]
        break if !word || (word == self.class.eof_marker && !options[:all])
        char = chars[offset]
        break if char == delimiter
        string << char
        offset += 1
      end
      string
    end
    
    def content_offset
      descriptor.size
    end

    def size(options={})
      # TODO Should :eof be the default? (Is there ever a meaningful eof marker in frozen files?)
      if options[:eof]
        eof_location = nil
        words.each_with_index do |word, index|
          if word.value == self.class.eof_marker
            eof_location = index
            break
          end
        end
        eof_location || size
      elsif options[:all]
        @words.size
      else
        file_size
      end
    end
    
    def file_size
      res = (words[0].half_word[1])+1
      res = res.value unless res.is_a?(Fixnum)
      res
    end

    def date(location)
      date_string = content[location,2].characters.string
      self.class.date(date_string)
    end
    
    def time_of_day(location)
      self.class.time_of_day content[location]
    end
    
    def time(date_location, time_location)
      self.class.time date(date_location), time_of_day(time_location)
    end

    def characters_per_word
      self.class.characters_per_word
    end
    
    def packed_characters_per_word
      self.class.packed_characters_per_word
    end
  
    # Allow file.path, etc.
    def method_missing(meth, *args, &blk)
      descriptor.send(meth, *args, &blk)
    rescue NoMethodError
      raise NoMethodError, "#{self.class}##{meth} method not defined"
    end
    
    
    # Is this file frozen?
    # Yes, if and only if it has a valid descriptor
    def frozen?
      defroster = Defroster.new(self)
      descriptor = Defroster::Descriptor.new(defroster, 0, :allow=>true)
      descriptor.valid?
    end
  end
end
