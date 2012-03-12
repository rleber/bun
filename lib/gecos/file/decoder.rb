class GECOS
  class Decoder < GECOS::File
    attr_reader :errors
    attr_accessor :keep_deletes
    
    # TODO do we ever instantiate a Decoder without reading a file? If not, refactor
    def initialize(options={})
      @keep_deletes = options[:keep_deletes]
      super
    end
    
    def words=(words)
      super
      if @words.nil?
        @text = @deblocked_content = nil
      end
      words
    end
    
    def text
      @text ||= _text
    end
    
    def _text
      lines.map{|l| l[:content]}.join
    end
    private :_text
    
    def lines
      @lines ||= unpack
    end
    
    def deblocked_content
      @deblocked_content ||= _deblocked_content
    end
    
    # TODO Build a capability in Slicr to do things like this
    def _deblocked_content
      deblocked_content = []
      offset = 0
      block_number = 1
      loop do
        break if offset >= size
        break if content[offset] == 0
        puts "offset=#{offset.inspect}, size=#{size.inspect}"
        block_size = content[offset].byte[-1]
        raise "Bad block number at #{'%o' % offset}: expected #{'%06o' % block_number}; got #{content[offset].half_word[0]}" unless content[offset].half_word[0] == block_number
        deblocked_content += content[offset+1..(offset+block_size)]
        offset += 0500
        block_number += 1
      end
      GECOS::Words.new(deblocked_content)
    end
    private :_deblocked_content
    
    def unpack
      deblocked_content = self.deblocked_content
      line_offset = 0
      lines = []
      warned = false
      errors = 0
      n = 0
      while line_offset < deblocked_content.size
        line = unpack_line(deblocked_content, line_offset)
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