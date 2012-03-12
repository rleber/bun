class GECOS
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
      
      def initialize(defroster, number, options={})
        @defroster = defroster
        @decoder = defroster.decoder
        @number = number
        raise "Bad descriptor block #{dump}" unless options[:allow] || valid?
      end
      
      def offset # Offset from the beginning of the file content, in words
        defroster.offset + DESCRIPTOR_OFFSET + number*DESCRIPTOR_SIZE
      end
      
      def characters(start, length)
        @decoder.characters[offset*Decoder.characters_per_word + start, length].join
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
        Decoder.date(_update_date)
      end
      
      def _update_date
        characters(8,8)
      end
      
      def update_time_of_day
        Decoder.time_of_day(_update_time_of_day)
      end
      
      def _update_time_of_day
        word(4)
      end
      
      def update_time
        Decoder.time(_update_date, _update_time_of_day)
      end
      
      def file_blocks
        word(6).value
      end
      
      def self.block_size
        BLOCK_SIZE  # In words
      end
      
      def block_size
        self.class.block_size
      end
      
      def file_start
        word(7).value
      end
      
      def file_words
        word(8).value
      end
      
      def valid?
        (check_text == 'asc ') && (check_word == DESCRIPTOR_END_MARKER)
      end
      
      def check_text
        characters(20,4)
      end
      
      def check_word
        word(9)
      end
      
      def hex
        @decoder.hex[offset*(decoder.bits_per_word/4), DESCRIPTOR_SIZE*decoder.bits_per_word/4]
      end

      def octal
        @decoder.octal[offset*(decoder.bits_per_word/3), DESCRIPTOR_SIZE*decoder.bits_per_word/3]
      end
    end
  end
end
