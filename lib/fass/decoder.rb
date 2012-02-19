class Fass
  class Decoder
    attr_reader :raw
    
    EOF_MARKER = 0x00000f000 # Octal 000000170000 or 0b000000000000000000001111000000000000
    CHARACTERS_PER_WORD = 4
    BITS_PER_WORD = 36
    
    def self.characters_per_word
      CHARACTERS_PER_WORD
    end
    
    def characters_per_word
      self.class.characters_per_word
    end
    
    def self.bits_per_word
      BITS_PER_WORD
    end
    
    def bits_per_word
      self.class.bits_per_word
    end
    
    def initialize(raw)
      @raw = raw
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
    
    # Raw data from file in 36-bit words (cached)
    def words
      @words ||= _words
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