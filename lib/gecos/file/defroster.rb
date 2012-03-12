require 'gecos/file/freezer_descriptor'

class GECOS
  class Defroster
    attr_reader :file, :errors
    attr_accessor :strict, :warn
    
    # TODO do we ever instantiate a Defroster without a new file? If not, refactor
    def initialize(file, options={})
      @file = file
      @strict = options[:strict]
      @warn = options[:warn]
    end
    
    def offset
      file.content_offset
    end
    
    def words
      @words ||= _words
    end
    
    def characters_per_word
      file.characters_per_word
    end
    
    def _words
      file.words[offset..-1]
    end
    private :_words
    
    def word_length
      words[0]
    end
    
    def files
      words[1]
    end
    
    def characters(*args)
      file.characters(*args)
    end
      
    def update_date
      File.date(_update_date)
    end
  
    def _update_date
      characters(2*characters_per_word, 8)
    end
    
    def update_time_of_day
      File.time_of_day(_update_time_of_day)
    end
    
    def _update_time_of_day
      words[4]
    end
    
    def update_time
      File.time(_update_date, _update_time_of_day)
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
    
    def file_names
      (0...files).map{|n| file_name(n)}
    end
    
    def file_path(n=nil)
      return file.file_path if n.nil?
      d = descriptor(n)
      return nil unless d
      Shell.relative_path(file.file_path, d.file_name)
    end
    
    def file_paths
      (0...files).map{|n| file_path(n)}
    end
    
    # Convert a file name to an index number; also convert negative indexes
    # Allowed formats:
    # Numeric: Any integer. 1..<# files> or -<# files>..-1 (counting backwards)
    # String:  [+-]\d+ : same as an Integer (Use leading '+' to ensure non-ambiguity -- '+1' is the
    #                    first file, '1' is the file named '1')
    #          Other:    Name of file. Ignore leading '\\' if any -- this allows a way to specify
    #                    a file name starting with '+', as for instance '+OneForParty'
    def fn(n)
      if n.is_a?(Numeric) || n.to_s =~ /^[+-]\d+$/
        orig_n = n
        n = n.to_i if n.is_a?(String)
        n += files+1 if n<0
        abort "Frozen file does not contain file number #{orig_n}" if n<1 || n>files
        n -= 1
      else
        name = n.to_s.sub(/^\\/,'') # Remove leading '\\', if any
        n = file_index(name)
        abort "Frozen file does not contain a file #{name}" unless n
      end
      n
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
    private :_content
    
    def lineset
      @lineset ||= _lineset
    end
    
    def _lineset
      (0...files).map {|i| _lines(i)}
    end
    private :_lineset
    
    def lines(n)
      @lineset ||= []
      @lineset[n] ||= thaw(n)
    end

    def thaw(n)
      words = file_words(n)
      line_offset = 0
      lines = []
      warned = false
      errors = 0
      while line_offset < words.size
        last_line_word, line, okay = thaw_line(words, line_offset)
        if !line
          abort "Bad line at #{'%o'%line_offset}: #{line.inspect}" if @strict
          Kernel.warn "Bad lines corrected" if !warned && @warn
          warned = true
          line_offset += 1
        else
          raw_line = line
          line.sub!(/\r\0*$/,"\n")
          lines << {:content=>line, :offset=>line_offset, :descriptor=>words[line_offset], 
                    :words=>words[line_offset..last_line_word], :raw=>raw_line}
          line_offset = last_line_word + 1
        end
        errors += 1 unless okay
      end
      @errors = errors
      lines
    end
    
    # TODO Refactor like File::Text#unpack_line
    def thaw_line(words, line_offset)
      line = ""
      line_length = words.size
      offset = line_offset
      okay = true
      loop do
        word = words[offset]
        break unless word
        ch_count = 5
        if line==""
          if good_descriptor?(word)
            line_length = line_length(word)
            ch_count = 3
          else
            okay = false
          end
        end
        chs = extract_characters(word, ch_count)
        line += chs.sub(/#{File.invalid_character_regexp}.*/,'') # Remove invalid control characters and all following letters
        break if chs=~/\r/
        if !good_characters?(chs) || line.size >= line_length
          okay = false
          break
        end
        offset += 1
      end
      return [offset, nil, false] unless line =~ /\r/
      [offset, line, okay]
    end
    
    def line_length(word)
      (word & 0x00fe00000) >> 21
    end
    
    def top_descriptor_bits(word)
      (word & 0xff0000000) >> 28
    end
    
    def good_descriptor?(word)
      top_descriptor_bits(word) == 0
    end
    
    def extract_characters(word, n=5)
      chs = []
      n.times do |i|
        chs.unshift((word & 0x7f).chr)
        word >>= 7
      end
      chs.join
    end
    
    def good_characters?(text)
      File.clean?(text.sub(/\0*$/,'')) && (text !~ /\0+$/ || text =~ /\r\0*$/) && text !~ /\n/
    end
  end
end
    