class Fass
  class Defroster
    attr_reader :decoder
    
    class Descriptor
      attr_reader :decoder, :number
      
      DESCRIPTOR_OFFSET = 5
      DESCRIPTOR_SIZE = 10
      BLOCK_SIZE = 64  # 36-bit words
      
      def self.size
        DESCRIPTOR_SIZE
      end
      
      def initialize(decoder, number)
        @decoder = decoder
        @number = number
        raise "Bad descriptor block #{dump}" unless verify
      end
      
      def offset # Offset from the beginning of the file content, in words
        Defroster.offset + DESCRIPTOR_OFFSET + number*DESCRIPTOR_SIZE
      end
      
      def characters(start, length)
        @decoder.characters[offset*Decoder.characters_per_word + start, length]
      end
      
      def words(start, length)
        @decoder.words[start+offset, length]
      end
      
      def word(start)
        words(start, 1).first
      end
      
      def file_name
        characters(0,8)
      end
      
      def update_date
        characters(8,8)
      end
      
      def file_blocks
        word(6)
      end
      
      def self.block_size
        BLOCK_SIZE  # In words
      end
      
      def block_size
        self.class.block_size
      end
      
      def file_start
        word(7)
      end
      
      def file_words
        word(8)
      end
      
      def verify
        (check_text == 'asc ') && (check_word == 0777777777777)
      end
      
      def check_text
        characters(20,4)
      end
      
      def check_word
        word(9)
      end
      
      def dump
        @decoder.hex[offset*(decoder.bits_per_word/4), DESCRIPTOR_SIZE*2]
      end
    end
    
    FILE_OFFSET = 15
    FROZEN_CHARACTERS_PER_WORD = 5
    
    def self.offset
      FILE_OFFSET
    end
    
    def initialize(decoder)
      @decoder = decoder
    end
    
    def words
      @words ||= _words
    end
    
    def _words
      decoder.words[FILE_OFFSET..-1]
    end
    private :_words
    
    def word_length
      words[0]
    end
    
    def files
      words[1]
    end
    
    def characters
      @characters ||= _characters
    end
    
    def _characters
      decoder.characters[(FILE_OFFSET*Decoder.characters_per_word)..-1]
    end
    private :_characters
    
    def update_date
      characters[2*Decoder.characters_per_word, 8]
    end
    
    def update_time
      words[4]
    end
    
    def descriptors
      @descriptors ||= _descriptors
    end
    
    def _descriptors
      (0...files).map do |i|
        Descriptor.new(decoder, i)
      end
    end
    private :_descriptors
    
    def descriptor(n)
      descriptors[n]
    end
    
    def contents
      @contents ||= contents
    end
    
    def _contents
      (0...files).map {|i| _content(i)}
    end
    private :_contents
    
    def content(n)
      @contents ||= []
      @contents[n] ||= _content(n)
    end
    
    def _content(n)
      trace = false
      trace_count = 0
      d = descriptor(n)
      words = decoder.words[d.file_start + FILE_OFFSET, d.file_words]
      line_offset = 0
      text = ""
      while line_offset < words.size
        line_length = (words[line_offset] & 0xfffe00000) >> 21
        puts "New line: length = #{line_length}" if trace
        word_offset = 0
        word = words[line_offset] & 0x1fffff
        puts "word: #{word.inspect} at offset #{line_offset}" if trace
        line = ""
        ch_count = 3
        loop do
          chs = []
          ch_count.times do |i|
            chs.unshift((word & 0x7f).chr)
            word >>= 7
          end
          line += chs.join
          puts "Characters: #{chs.join.inspect}" if trace
          break if line.size >= line_length
          word_offset += 1
          word = words[line_offset + word_offset]
          break unless word
          puts "word: #{word.inspect} at offset #{line_offset} + #{word_offset}" if trace
          ch_count = 5
        end
        line = line[0, line_length].gsub(/\r/,"\n")
        trace = true if line =~ /SMEDLEY:\s+What does what do/
        trace_count += 1 if trace
        puts trace_count
        exit if trace_count > 2
        line_offset += word_offset + 1
        text += line
      end
      exit
      text
    end
    private :_content
  end
end
    