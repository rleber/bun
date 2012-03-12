require 'gecos/word'

class GECOS
  class File
    
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
        File.expand_path(File.join(*f), ENV['HOME']).sub(/^#{Regexp.escape(ENV['HOME'])}\//,'')
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
    end
    
    CHARACTERS_PER_WORD = characters_per_word
    PACKED_CHARACTERS_PER_WORD = packed_characters_per_word
    ARCHIVE_NAME_POSITION = 7 # words
    SPECIFICATION_POSITION = 11 # words
    DESCRIPTION_PATTERN = /\s+(.*)/
    
    attr_reader :words, :content, :all_characters, :characters, :packed_characters
    
    def initialize(options={}, &blk)
      file = options[:file]
      data = options[:data]
      words = options[:words]
      if file
        @words = GECOS::Words.read(file)
      elsif data
        @words = decode(data)
      else
        @words = words
      end
      @content = LazyArray.new do |n|
        return nil if n >= self.size
        @words[content_offset+n]
      end
      @all_characters = LazyArray.new do |n|
        @words.characters[n]
      end
      @characters = LazyArray.new do |n|
        @content.characters[n]
      end
      @packed_characters = LazyArray.new do |n|
        @content.packed_characters[n]
      end
      yield(self) if block_given?
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
        break if !word || (word == EOF_MARKER && !options[:all])
        char = chars[offset]
        break if char == delimiter
        string << char
        offset += 1
      end
      string
    end
    
    def content_offset
      SPECIFICATION_POSITION + (specification.size + 4)/4
    end

    def size(options={})
      # TODO Should :eof be the default? (Is there ever a meaningful eof marker in frozen files?)
      if options[:eof]
        eof_location = content.find {|word| word.value == self.class.eof_marker }
        eof_location || size
      elsif options[:all]
        @words.size
      else
        (words[0].half_word[1])+1
      end
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
    
    def specification
      delimited_string SPECIFICATION_POSITION*CHARACTERS_PER_WORD
    end
    
    def archive_name
      delimited_string ARCHIVE_NAME_POSITION*CHARACTERS_PER_WORD
    end
    
    def subpath
      specification.sub(DESCRIPTION_PATTERN,'').sub(/^\//,'')
    end
    
    def subdirectory
      d = File.dirname(subpath)
      d = "" if d == "."
      d
    end

    def name
      File.basename(subpath)
    end
    
    def description
      specification[DESCRIPTION_PATTERN,1] || ""
    end
    
    def path
      self.class.relative_path(archive_name, subpath)
    end
    
    def unexpanded_path
      File.join(archive_name, subpath)
    end
    
    def characters_per_word
      self.class.characters_per_word
    end
    
  end
end
