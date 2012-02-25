class Array
  def index_at(starting_index, search_for)
    index = starting_index
    loop
      return nil if index >= self.size
      return self[index] if self[index] == search_for
      index += 1
    end
  end
end

class GECOS
  class Word
    BITS_PER_WORD = 36
    
    def bit_count
      BITS_PER_WORD
    end
    
    # Convert an index (which might be negative) to a positive one
    def _convert_index(ix)
      _ensure_numeric_argument(ix, "index")
      ix = (self.size+ix) if ix<0
      ix
    end
    private :_convert_index

    def _ensure_numeric_argument(ix, label)
      raise TypeError, "Non-numeric #{label} #{ix.inspect} for #{self.class}" unless ix.is_a?(Fixnum)
    end

    # Convert an index specification to a range of individual indexes
    # An index specification might be a single index, a (start, length) pair, or
    # a Range
    def _convert_indexes(*args)
      indexes = case args.size
      when 1
        ix = args.first
        if ix.is_a?(Range)
          [ix.begin, ix.end + (ix.exclude_end? ? -1 : 0)]
        else
          [ix, ix]
        end
      when 2
        start, length = args
        start = _convert_index(start)
        [start, start + length - 1]
      else
        raise ArgumentError, "wrong number of arguments: #{args.size} for 1 or 2"
      end
      indexes = indexes.map {|ix| _convert_index(ix) }
      (indexes.first..indexes.last)
    end

    # Define generalized indexing in terms of at(ix)
    def [](*args)
      range = _convert_indexes(*args)
      # Handle special cases
      return nil if range.begin < 0 || range.begin > self.size
      range.end = Range.new(range.begin, self.size-1) if range.begin >= self.size
      range.map{|ix| self.at(ix) }
    end

    def []=(*args)
      raise ArgumentError, "wrong number of arguments: #{args.size} for 2 or 3" unless [2,3].include?(args.size)
      value = args.pop
      if args.size == 2
        length = args[1]
        _ensure_numeric_argument(length, "length")
        raise IndexError, "Negative length #{length} for #{self.class}" if length < 0
      end
      indexes = _convert_indexes(*args)
      raise IndexError, "Starting index #{indexes.first} out of range for #{self.class}" unless indexes.first >= 0
      raise IndexError, "Ending index #{indexes.last} out of range for #{self.class}" unless indexes.last >= 0
      if value.nil? &&  # Deleting
        (0...indexes.size).each {|ct| self.delete_at(indexes.begin) } # Works because index changes on each iteration
      elsif indexes.end < indexes.begin # Inserting; this will also happen if for ary[2,0]= ...
        # TODO Complete implementing this
      else # Setting
        # TODO Complete implementing this
      end
      value
    end
    
    def bits(*args)
      case
  end
  
  class Data
    
    CHARACTERS_PER_WORD = 4
    
    def self.bits_per_word
      BITS_PER_WORD
    end
    
    def bits_per_word
      self.class.bits_per_word
    end
    
    def zstring(start_at)
      characters[start_at...characters.index_at(start_at, "\0")].join
    end
    
    def string(*args)
      characters[*args].join
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
      Shell.relative_path(file_specification.sub(DESCRIPTION_PATTERN,'').sub(/^\//,''))
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
    
    # TODO do we ever instantiate a Data without reading a file? If not, refactor
    def initialize(raw, options={})
      self.raw = raw
      @keep_deletes = options[:keep_deletes]
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
    
    def word_count
      [(words[0] & 0777777)+1, words.size].min
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
      @lines ||= unpack
    end
    
    def unpack
      # line_offset = file_content_start + UNPACK_OFFSET
      line_offset = file_content_start + 22
      lines = []
      warned = false
      errors = 0
      n = 0
      while line_offset < word_count
        line = unpack_line(words, line_offset)
        line[:status] = :ignore if n == 0
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
    def unpack_line(words, line_offset)
      # puts "  unpack at #{'%06o' % line_offset}"
      line = ""
      raw_line = ""
      okay = true
      descriptor = words[line_offset]
      if descriptor == 0
        current_block = (line_offset - file_content_start).div(BLOCK_SIZE)
        first_word_in_next_block = (current_block + 1)*BLOCK_SIZE + file_content_start + UNPACK_OFFSET - 1
        # puts "  skip to block #{current_block + 1} at #{'%06o' % first_word_in_next_block}"
        return {:status=>:ignore, :start=>line_offset, :finish=>first_word_in_next_block, :content=>nil, :raw=>nil, :words=>nil, :descriptor=>descriptor}
      end
      if descriptor == EOF_MARKER
        return {:status=>:eof, :start=>line_offset, :finish=>word_count, :content=>nil, :raw=>nil, :words=>nil, :descriptor=>descriptor}
      elsif (descriptor >> 27) & 0777 == 0177
        # puts "  deleted (descriptor[0] == 0177)"
        deleted = true
        line_length = word_count
      elsif (descriptor >> 27) & 0777 == 0
        # if descriptor & 0777 == 0600
          # puts "  normal (descriptor[0] == 0 && descriptor[3] == 0600): line_length = #{line_length}"
          line_length = line_length(descriptor)
        # else
        #   raise "Unexpected line descriptor (byte 3). Descriptor=#{'%012o' % descriptor} at #{'%06o' % line_offset}" unless descriptor & 0777 == 0
        #   return {:status=>:delete, :start=>line_offset, :finish=>line_offset+1, :content=>line, :raw=>raw_line, :words=>words[line_offset, 2], :descriptor=>descriptor}
        # end
      else # Sometimes, there is ASCII in the descriptor word; In that case, capture it, and look for terminating "\177"
        # puts "  indeterminate ASCII"
        line_length = word_count
        chs = extract_characters(descriptor)
        line += chs
        raw_line += chs
      end
      offset = line_offset+1
      loop do
        word = words[offset]
        break if !word || word == EOF_MARKER
        chs = extract_characters(word)
        # puts "  at #{'%06o' % offset}: descriptor=#{'%012o' % descriptor}, line_length=#{'%06o' % line_length}, word=#{'%012o' % word}, chs=#{chs.inspect}"
        raw_line += chs
        clipped_chs = chs.sub(/#{INVALID_CHARACTER_REGEXP}.*/,'') # Remove control characters and all following letters
        line += clipped_chs
        break if (offset-line_offset) >= line_length
        break if chs =~ /\177+$/
        if clipped_chs != chs || clipped_chs.size==0 || !good_characters?(chs)
          okay = false
          break
        end
        offset += 1
      end
      # puts "  emit"
       line += "\n"
      {:status=>(okay ? :okay : :error), :start=>line_offset, :finish=>offset, :content=>line, :raw=>raw_line, :words=>words[line_offset..offset], :descriptor=>descriptor}
    end
    
    def line_length(word)
      (word & 0777777000000) >> 18
    end
    
    def line_flags(word)
      word & 0777777
    end
    
    def byte(word, n)
      extract_bytes(word)[n]
    end
    
    def oddball_line?(word)
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
      Data.clean?(text.gsub(/\t/,'').sub(/\177*$/,'')) && (text !~ /\177/ || text =~ /[^\177]+\177+$/) && text !~ /[\n\r]/
    end
  end
end