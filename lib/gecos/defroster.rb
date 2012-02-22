require 'gecos/freezer_descriptor'

class GECOS
  class Defroster
    attr_reader :decoder
    
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
      decoder.characters[(offset*Decoder.characters_per_word)..-1]
    end
    private :_characters
      
    def update_date
      Decoder.date(_update_date)
    end
  
    def _update_date
      characters[2*Decoder.characters_per_word, 8]
    end
    
    def update_time_of_day
      Decoder.time_of_day(_update_time_of_day)
    end
    
    def _update_time_of_day
      words[4]
    end
    
    def update_time
      Decoder.time(_update_date, _update_time_of_day)
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
      Decoder.clean?(text.sub(/\0*$/,'')) && (text !~ /\0+$/ || text =~ /\r\0*$/) && text !~ /\n/
    end
    
    def self.line_ended?(text)
      text =~ /\r\0*$/
    end
    
    def self.zero_top_bit?(word)
      (word & 0x800000000)==0
    end
    
    def self.defrost_line(words, line_offset, options={})
      line = ""
      line_length = words.size
      offset = line_offset
      loop do
        word = words[offset]
        break unless word
        ch_count = 5
        if line==""
          if good_descriptor?(word)
            line_length = line_length(word)
            ch_count = 3
          end
        end
        chs = extract_characters(word, ch_count)
        line += chs.sub(/[[:cntrl:]].*/){|s| s[/^\r?/]} # Remove control characters (except trailing \r) and all following letters
        break if chs=~/\r/ || !good_characters?(chs) || line.size >= line_length
        offset += 1
      end
      return [line_offset, offset, nil] unless line =~ /\r/
      [line_offset, offset, line]
    end
    
    def self.words_required(line)
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
      warned = false
      while line_offset < words.size
        success = false
        _, last_line_word, line = defrost_line(words, line_offset, options)
        if !line
          abort "Bad line at #{'%o'%line_offset}: #{line.inspect}" if options[:strict]
          warn "Bad lines corrected" if !warned && options[:warn]
          warned = true
          line_offset += 1
        else
          raw_line = line
          line.sub!(/\r\0*$/,"\n")
          lines << {:content=>line, :offset=>line_offset, :descriptor=>words[line_offset], 
                    :words=>words[line_offset..last_line_word], :raw=>raw_line}
          line_offset = last_line_word + 1
        end
      end
      lines
    end
  end
end
    