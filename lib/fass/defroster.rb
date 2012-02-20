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
      
      def hex
        @decoder.hex[offset*(decoder.bits_per_word/4), DESCRIPTOR_SIZE*decoder.bits_per_word/4]
      end

      def octal
        @decoder.octal[offset*(decoder.bits_per_word/3), DESCRIPTOR_SIZE*decoder.bits_per_word/3]
      end
    end
    
    def offset
      decoder.file_content_start
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
      if n == files-1
        words[d.file_start..-1]
      else
        words[d.file_start, d.file_words]
      end
    end
    
    def contents
      @contents ||= _contents
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
      lines(n).map{|l| l[:content]}.join
    end
    
    def lineset
      @lineset ||= _lineset
    end
    
    def _lineset
      (0...files).map {|i| _lines(i)}
    end
    private :_contents
    
    def lines(n)
      @lineset ||= []
      @lineset[n] ||= self.class.defrost(file_words(n))
    end
    
    def self.line_length(word)
      (word & 0xfffe00000) >> 21
    end
    
    def self.clipped_line_length(word)
      (word & 0x00fe00000) >> 21
    end
    
    def self.top_descriptor_bits(word)
      (word & 0xff0000000) >> 28
    end
    
    def self.bottom_descriptor_bits(word)
      word & 0x1fffff
    end
    
    def self.good_descriptor?(word)
      top_descriptor_bits(word) == 0
    end
    
    def self.extract_characters(word, n=5)
      chs = []
      n.times do |i|
        chs.unshift((word & 0x7f).chr)
        word >>= 7
      end
      chs.join
    end
    
    def self.good_characters?(text)
      Decoder.clean?(text.sub(/\0*$/)) && text=~/(\r\0*$)?/ && text !~ /\n/
    end
    
    def self.line_ended?(text)
      text =~ /\r\0*$/
    end
    
    def self.zero_top_bit?(word)
      (word & 0x800000000)!=0
    end
    
    def self.defrost_line(words, line_offset, options={})
      descriptor = words[line_offset]
      return nil unless descriptor
      line_length = line_length(descriptor)
      top_bits = top_descriptor_bits(descriptor)
      warn "Non-zero top bits (#{'%03o'%top_bits}) at #{'%o'%line_offset}" if options[:warn] && top_bits!=0
      puts "New line: length = #{line_length}" if options[:trace]
      word = bottom_descriptor_bits(descriptor)
      puts "First word: #{word.inspect} at #{'%o'%line_offset}" if options[:trace]
      line = ""
      ch_count = 3
      offset = line_offset
      loop do
        warn "Non-zero top bit in character word at #{'%o'%offset}: #{'%o'%word}" \
            if options[:warn] && zero_top_bit?(word)
        line += extract_characters(word, ch_count)
        puts "Characters: #{chs.join.inspect}" if options[:trace]
        break if line.size >= line_length
        offset += 1
        word = words[offset]
        break unless word
        warn "Word: #{word.inspect} at #{'%o'%offset}" if options[:trace]
        ch_count = 5
      end
      [line_offset, offset, line]
    end
    
    def self.words_required
      line = line.sub(/\0+$/,'')
      return 2 if line.size < 3
      2 + (line.size - 3 + 4)/5
    end
    
    def self.options
      @options
    end
    
    def self.options=(options)
      @options=options
    end
    
    def options=(options)
      self.class.options=options
    end
    
    def options
      self.class.options
    end
    
    # TODO Should this not be a class method?
    def self.defrost(words, options={})
      options = self.options.merge(options)
      trace_count = 0
      line_offset = 0
      lines = []
      while line_offset < words.size
        success = false
        next_line_offset = line = nil
        loop do
          _, last_line_word, line = defrost_line(words, line_offset, options)
          next_line_offset = last_line_word + 1
          break unless options[:strict] || options[:repair] || options[:warn]
          break if Decoder.clean?(line.sub(/\0+$/,''))
          abort "Bad line at #{'%o'%line_offset}: #{line.inspect}" if options[:strict]
          warn "Bad line at #{'%o'%line_offset}: #{line.inspect}"
          break unless options[:repair]
          # Attempt to repair the line
          # Truncate this line at the first bad character
          flaw_location = Decoder.find_flaw(line)
          line = line[0...flaw_location] + "\r"
          last_line_word = line_offset + words_required(line)
          # Look for a possible next line
          next_line_offset, next_line_end, next_line = find_good_line(words, last_line_word + 1)
          abort "Next line isn't clean: #{next_line.inspect}" unless Decoder.clean?(next_line)
          if next_line_offset
            # Cause the stub of the last line to be inserted, and restart with the new line
            words[next_line_offset..next_line_end] = freeze(next_line)
          else
            warn "Unable to find any more good data. Terminating"
            next_line_offset = words.size # Force termination of the loop
          end
        end
        raw_line = line
        line = line[0, line_length].gsub(/\r\0*/,"\n")
        lines << {:content=>line, :offset=>line_offset, :descriptor=>descriptor, 
                  :words=>words[line_offset..last_line_word], :raw=>raw_line}
        options[:trace] = true if options[:sentinel] && line =~ options[:sentinel]
        trace_count += 1 if options[:trace]
        exit if options[:trace] && options[:trace_limit] && trace_count > options[:trace_limit]
        line_offset += next_line_offset
      end
      lines
    end
    private :_content
    
    # Find a possible good line of text
    # Look for a sequence of consecutive words that could be a line:
    #   - Every word has a zero top bit
    #   - First word is possibly 0b00000000lllllll<ch1><ch2><ch3> (bit pattern /$0{8}.{7}.{21}$/)
    #   - Every character in each word is not a control character (excluding tabs)
    #   - Last word is in the form /\r\0*$/
    def self.find_good_line(words, search_offset)
      line = ""
      start_offset = search_offset
      offset = nil
      loop do
        # See if there's a valid line, starting at start_offset
        offset = start_offset
        success = true
        return [nil, nil, nil] unless words[offset]
        if good_descriptor?(words[offset])
          chars = extract_characters(word[offset],3)
          if good_characters?(chars) # Good descriptor
            line += chars
            offset += 1
          else # Bad descriptor; also a bad "characters" word (because of the zero top bits)
            start_offset += 1
            next
          end
        end
        loop do
          break if line_ended?(line) # Found the end of the line
          # Look for a sequence of good "character" words
          word = words[offset]
          unless zero_top_bit?(word)
            success = false
            break
          end
          chars = extract_characters(word, 5)
          unless good_characters?(chars)
            success = false
            break
          end
          line += chars
          offset += 1
        end
        break unless success
      end
      [start_offset, offset-1, line]
    end
  end
end
    