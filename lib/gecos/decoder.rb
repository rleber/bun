class GECOS
  class Decoder
    attr_reader :raw
    
    EOF_MARKER = 0x00000f000 # Octal 000000170000 or 0b000000000000000000001111000000000000
    CHARACTERS_PER_WORD = 4
    BITS_PER_WORD = 36
    ARCHIVE_NAME_POSITION = 7 # words
    SPECIFICATION_POSITION = 11 # words
    
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
    
    def file_specification
      zstring SPECIFICATION_POSITION*CHARACTERS_PER_WORD
    end
    
    def file_archive_name
      zstring ARCHIVE_NAME_POSITION*CHARACTERS_PER_WORD
    end
    
    DESCRIPTION_PATTERN = /\s+==>\s+(.*?)\s*$/
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
  end
end