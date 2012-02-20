class Fass
  class Defroster
    attr_reader :decoder
    
    class Descriptor
      attr_reader :defroster, :decoder, :number
      
      DESCRIPTOR_OFFSET = 5
      DESCRIPTOR_SIZE = 10
      BLOCK_SIZE = 64  # 36-bit words
      DESCRIPTOR_END_MARKER = 0777777777777
      
      def self.offset
        DESCRIPTOR_OFFSET
      end
      
      def self.size
        DESCRIPTOR_SIZE
      end
      
      def self.end_marker
        DESCRIPTOR_END_MARKER
      end
      
      def initialize(defroster, number)
        @defroster = defroster
        @decoder = defroster.decoder
        @number = number
        raise "Bad descriptor block #{dump}" unless verify
      end
      
      def offset # Offset from the beginning of the file content, in words
        defroster.offset + DESCRIPTOR_OFFSET + number*DESCRIPTOR_SIZE
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
        characters(0,8).strip
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
        (check_text == 'asc ') && (check_word == DESCRIPTOR_END_MARKER)
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
    
    def offset
      @offset ||= _offset
    end
    
    def _offset
      index = 0
      decoder.words.each_with_index {|word, index| break if word == Descriptor.end_marker }
      raise "No descriptor end markers found" if index > decoder.words.size
      index - Descriptor.offset - Descriptor.size + 1
    end
    
    def initialize(decoder)
      @decoder = decoder
    end
    
    def words
      @words ||= _words
    end
    
    def _words
      decoder.words[offset..-1]
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
        Descriptor.new(self, i)
      end
    end
    private :_descriptors
    
    def descriptor(n)
      descriptors[n]
    end
    
    def file_name(n)
      d = descriptor(n)
      return nil unless d
      d.file_name
    end
    
    def contents
      @contents ||= contents
    end
    
    def _contents
      (0...files).map {|i| _content(i)}
    end
    private :_contents
    
    def file_index(name)
      descr = descriptors.find {|d| d.file_name == name}
      if descr
        index = descr.number
      else
        index = nil
      end
      index
    end
    
    def file_words(n)
      d = descriptor(n)
      return nil unless d
      words[d.file_start, d.file_blocks*Descriptor.block_size]
    end
    
    def content(n)
      @contents ||= []
      @contents[n] ||= _content(n)
    end
    
    TRACE_ENABLED = false
    def _content(n)
      trace = false
      trace_count = 0
      d = descriptor(n)
      words = decoder.words[d.file_start + offset, d.file_words]
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
        trace = true if TRACE_ENABLED && line =~ /SMEDLEY:\s+What does what do/
        trace_count += 1 if trace
        line_offset += word_offset + 1
        text += line
      end
      text
    end
    private :_content
  end
end
    