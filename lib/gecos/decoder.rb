require 'gecos/word'

class GECOS
  class Decoder
    attr_reader :errors
    attr_accessor :keep_deletes, :words
    
    EOF_MARKER = 0x00000f000 # Octal 000000170000 or 0b000000000000000000001111000000000000
    CHARACTERS_PER_WORD = GECOS::Word.character.count
    BITS_PER_WORD = GECOS::Word.width
    ARCHIVE_NAME_POSITION = 7 # words
    SPECIFICATION_POSITION = 11 # words
    
    def zstring(offset)
      start = offset
      ch = characters
      loop do
        break if offset > ch.size
        break if ch[offset] == "\0"
        offset += 1
      end
      ch[start...offset].join
    end
    
    # Convert an eight-character GECOS date "mm/dd/yy" to a Ruby Date
    def self.date(date)
      Date.strptime(date,"%m/%d/%y")
    end
    
    # Convert a GECOS timestamp to the time of day in hours (24 hour clock)
    # Returns a three item array: hour, minutes, seconds (with embedded fractional seconds)
    TIME_SUM = 1620000 # additive offset for converting GECOS times
    TIME_DIV = 64000.0 # division factor for converting GECOS ticks to seconds
    def self.time_of_day(timestamp)
      timestamp = timestamp.integer.value
      seconds = (timestamp + TIME_SUM) / TIME_DIV
      minutes, seconds = seconds.divmod(60.0)
      hours, minutes = minutes.divmod(60.0)
      [hours, minutes, seconds]
    end
    
    # Convert a GECOS date and time into a Ruby Time
    def self.time(date, timestamp)
      hours, minutes, seconds = time_of_day(timestamp)
      seconds, frac = seconds.divmod(1.0)
      micro_seconds = (frac*1000000).to_i
      date = self.date(date)
      Time.local(date.year, date.month, date.day, hours, minutes, seconds, micro_seconds)
    end
    
    def file_specification
      zstring SPECIFICATION_POSITION*CHARACTERS_PER_WORD
    end
    
    def file_archive_name
      zstring ARCHIVE_NAME_POSITION*CHARACTERS_PER_WORD
    end
    
    DESCRIPTION_PATTERN = /\s+(.*)/
    def file_subpath
      file_specification.sub(DESCRIPTION_PATTERN,'').sub(/^\//,'')
    end
    
    def file_subdirectory
      d = File.dirname(file_subpath)
      d = "" if d == "."
      d
    end

    def file_name
      File.basename(file_subpath)
    end
    
    def file_description
      file_specification[DESCRIPTION_PATTERN,1] || ""
    end
    
    def file_path
      Shell.relative_path(file_archive_name, file_subpath)
    end
    
    def unexpanded_file_path
      File.join(file_archive_name, file_subpath)
    end
    
    def file_content_start
      SPECIFICATION_POSITION + (file_specification.size + 4)/4
    end
    
    def self.characters_per_word
      CHARACTERS_PER_WORD
    end
    
    def characters_per_word
      self.class.characters_per_word
    end
    
    VALID_CONTROL_CHARACTERS = '\r\t\n\b'
    VALID_CONTROL_CHARACTER_STRING = eval("\"#{VALID_CONTROL_CHARACTERS}\"")
    VALID_CONTROL_CHARACTER_REGEXP = /[#{VALID_CONTROL_CHARACTERS}]/
    INVALID_CHARACTER_REGEXP = /(?!(?>#{VALID_CONTROL_CHARACTER_REGEXP}))[[:cntrl:]]/
    VALID_CHARACTER_REGEXP = /(?!(?>#{INVALID_CHARACTER_REGEXP}))./
    
    def self.valid_control_character_regexp
      VALID_CONTROL_CHARACTER_REGEXP
    end
    
    def self.invalid_character_regexp
      INVALID_CHARACTER_REGEXP
    end
    
    def self.valid_character_regexp
      VALID_CHARACTER_REGEXP
    end
    
    def self.clean?(text)
      find_flaw(text).nil?
    end
    
    def self.find_flaw(text)
      text =~ INVALID_CHARACTER_REGEXP
    end
    
    def self.bits_per_word
      BITS_PER_WORD
    end
    
    def bits_per_word
      self.class.bits_per_word
    end
    
    # TODO do we ever instantiate a Decoder without reading a file? If not, refactor
    def initialize(options={})
      if options[:file]
        @words = GECOS::Words.read(options[:file])
      elsif options[:data]
        @words = GECOS::Words.import(options[:data])
      else
        @words = GECOS::Words[]
      end
      @keep_deletes = options[:keep_deletes]
    end
    
    def clear
      @words = nil
      @characters = nil
    end
    
    def word_count
      (words[0].half_word[1])+1
    end
    
    def characters
      @characters ||= words.characters
    end
    
    def packed_characters
      @packed_characters ||= words.packed_characters
    end
    
    def content
      @content ||= _content
    end
    
    def _content
      lines.map{|l| l[:content]}.join
    end
    private :_content
    
    def lines
      @lines ||= unpack
    end
    
    # TODO Build a capability in Slicr to do things like this
    def deblock
      deblocked_words = []
      offset = file_content_start
      block_number = 1
      loop do
        break if offset >= word_count
        break if words[offset] == 0
        block_size = words[offset].byte[-1]
        raise "Bad block number at #{'%o' % offset}: expected #{'%06o' % block_number}; got #{words[offset].half_word[0]}" unless words[offset].half_word[0] == block_number
        deblocked_words += words[offset+1..(offset+block_size)]
        offset += 0500
        block_number += 1
      end
      GECOS::Words.new(deblocked_words)
    end
    
    def unpack
      words = deblock
      line_offset = 0
      lines = []
      warned = false
      errors = 0
      n = 0
      while line_offset < words.size
        line = unpack_line(words, line_offset)
        line[:status] = :ignore if n==0
        case line[:status]
        when :eof     then break
        when :okay    then lines << line
        when :delete  then lines << line if @keep_deletes
        when :ignore  then # do nothing
        else               errors += 1
        end
        line_offset = line[:finish]+1
        n += 1
      end
      @errors = errors
      lines
    end
    
    BLOCK_SIZE = 0500
    # TODO simplify
    def unpack_line(words, line_offset)
      line = ""
      raw_line = ""
      okay = true
      descriptor = words[line_offset]
      if descriptor == EOF_MARKER
        return {:status=>:eof, :start=>line_offset, :finish=>word_count, :content=>nil, :raw=>nil, :words=>nil, :descriptor=>descriptor}
      elsif (descriptor >> 27) & 0777 == 0177
        raise "Deleted"
        deleted = true
        line_length = word_count
      elsif (descriptor >> 27) & 0777 == 0
          line_length = descriptor.half_word[0]
      else # Sometimes, there is ASCII in the descriptor word; In that case, capture it, and look for terminating "\177"
        raise "ASCII in descriptor"
      end
      offset = line_offset+1
      raw_line = words[offset,line_length].characters.join
      line = raw_line.sub(/\177+$/,'') + "\n"
      {:status=>(okay ? :okay : :error), :start=>line_offset, :finish=>line_offset+line_length, :content=>line, :raw=>raw_line, :words=>words[line_offset+line_length], :descriptor=>descriptor}
    end
  end
end