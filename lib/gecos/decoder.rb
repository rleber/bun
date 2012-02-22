class GECOS
  class Decoder
    attr_reader :raw
    
    EOF_MARKER = 0x00000f000 # Octal 000000170000 or 0b000000000000000000001111000000000000
    CHARACTERS_PER_WORD = 4
    BITS_PER_WORD = 36
    ARCHIVE_NAME_POSITION = 7 # words
    SPECIFICATION_POSITION = 11 # words
    UNPACK_OFFSET = 22
    
    def zstring(offset)
      start = offset
      ch = characters
      loop do
        break if offset > ch.size
        break if ch[offset,1] == "\0"
        offset += 1
      end
      ch[start...offset]
    end
    
    # Convert an eight-character GECOS date "mm/dd/yy" to a Ruby Date
    def self.date(date)
      Date.strptime(date,"%m/%d/%y")
    end
    
    # Convert two's complement encoded word to signed value
    def self.make_signed(word)
      if word & 0x800000000 > 0
        # Negative number
        -((~word)+1)
      else
        word
      end
    end
    
    # Convert a GECOS timestamp to the time of day in hours (24 hour clock)
    # Returns a three item array: hour, minutes, seconds (with embedded fractional seconds)
    TIME_SUM = 1620000 # additive offset for converting GECOS times
    TIME_DIV = 64000.0 # division factor for converting GECOS ticks to seconds
    def self.time_of_day(timestamp)
      timestamp = make_signed(timestamp)
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
    
    FILE_NAME_PATTERN = /\/([^\/]*)$/
    def file_subdirectory
      file_subpath.sub(FILE_NAME_PATTERN,'')
    end

    def file_name
      file_subpath[FILE_NAME_PATTERN,1] || ""
    end
    
    def file_description
      file_specification[DESCRIPTION_PATTERN,1] || ""
    end
    
    def file_path
      file_archive_name + '/' + file_subpath
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

    def self.clean?(text)
      bad_characters = text.gsub(/[^[:cntrl:]]|[\r\t\n]/,'')
      bad_characters.size == 0
    end
    
    def self.find_flaw(text)
      pos = text.gsub(/[\r\t\n]/,'').sub(/[[:cntrl:]].*/m, '').size
      return nil if pos >= text.size
      pos
    end
    
    def self.bits_per_word
      BITS_PER_WORD
    end
    
    def bits_per_word
      self.class.bits_per_word
    end
    
    def initialize(raw)
      self.raw = raw
    end
    
    def raw=(raw)
      clear
      @raw = raw
    end
    
    def clear
      @raw = nil
      @hex = nil
      @words = nil
      @bytes = nil
      @octal = nil
      @character = nil
      @frozen_characters = nil
    end
    
    # Raw data from file in hex; cached
    def hex
      @hex ||= _hex
    end
    
    # Raw data from file in hex
    def _hex
      raw.unpack('H*').first
    end
    private :_hex
    
    # Raw data from file in octal; cached
    def octal
      @octal ||= _octal
    end
    
    # Raw data from file in octal
    def _octal
      raw.unpack('B*').first.scan(/.../).map{|o| '%o'%eval('0b'+o)}.join
    end
    private :_octal
    
    def hex=(hex)
      self.raw = [hex].pack('H*')
    end
    
    # Raw data from file in 36-bit words (cached)
    def words
      @words ||= _words
    end
    
    def words=(words)
      self.hex = words.map{|w| '%09x' % w }.join
    end
    
    # Raw data from file in 36-bit words
    def _words
      hex.scan(/.{9}/).map{|w| w.hex}
    end
    private :_words
    
    def bytes
      @bytes ||= _bytes
    end
    
    def _bytes
      words.map do |w|
        chars = []
        4.times do |i|
          chars.unshift( w & 0x1ff )
          w = w >> 9
        end
        chars
      end.flatten
    end
    private :_bytes
    
    def characters
      @characters ||= _characters
    end
    
    def _characters
      bytes.map do |b|
        ch = b > 255 ? "\000" : b.chr
        ch
      end.join
    end
    private :_characters
    
    def frozen_characters
      @frozen_characters ||= _frozen_characters
    end
    
    def _frozen_characters
      words.map do |w|
        chars = []
        5.times do |i|
          chars.unshift( (w & 0x7f).chr )
          w = w >> 7
        end
        chars.join
      end.join
    end
    private :_frozen_characters
    
    def content
      @content ||= _content
    end
    
    def _content
      lines.map{|l| l[:content]}.join
    end
    private :_content
    
    def lines
      @lines ||= decode
    end
    
    def decode
      line_offset = file_content_start + UNPACK_OFFSET
      lines = []
      warned = false
      while line_offset < words.size
        _, last_line_word, line = decode_line(words, line_offset)
        if line
          raw_line = line
          line.sub!(/\r\0*$/,"\n")
          lines << {:content=>line, :offset=>line_offset, :descriptor=>words[line_offset], 
                    :words=>words[line_offset..last_line_word], :raw=>raw_line}
        end
        line_offset = last_line_word + 1
      end
      lines
    end
    
    def decode_line(words, line_offset)
      line = ""
      descriptor = words[line_offset]
      return [line_offset, words.size, nil] if descriptor == EOF_MARKER
      deleted = deleted_line?(descriptor)
      line_length = line_length(descriptor)
      offset = line_offset+1
      loop do
        word = words[offset]
        break if !word || word == EOF_MARKER
        chs = extract_characters(word)
        clipped_chs = chs.sub(/(?!\t)[[:cntrl:]].*/,'') # Remove control characters and all following letters
        line += clipped_chs
        break if clipped_chs != chs || clipped_chs.size==0 || !good_characters?(chs) || (offset-line_offset) >= line_length
        offset += 1
      end
      return [line_offset, offset, nil] if deleted
      line += "\n"
      [line_offset, offset, line]
    end
    
    def line_length(word)
      (word & 0777777000000) >> 18
    end
    
    def byte(word, n)
      extract_bytes(word)[n]
    end
    
    def deleted_line?(word)
      byte(word,0) != 0
    end
    
    def extract_characters(word, n=5)
      extract_bytes(word).map{|c| (c & 0600) > 0 ? 0 : c.chr }.join
    end
    
    def extract_bytes(word)
      chs = []
      4.times do |i|
        chs.unshift(word & 0777)
        word >>= 9
      end
      chs
    end
    
    def good_characters?(text)
      Decoder.clean?(text.gsub(/\t/,'').sub(/\177*$/,'')) && (text !~ /\177/ || text =~ /[^\177]+\177+$/) && text !~ /[\n\r]/
    end
  end
end