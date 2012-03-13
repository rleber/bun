class GECOS
  class File
    class Frozen < GECOS::File
      attr_reader :file, :errors
      attr_accessor :strict, :warn
    
      # TODO do we ever instantiate a File::Frozen without a new file? If not, refactor
      def initialize(options={})
        super
        @strict = options[:strict]
        @warn = options[:warn]
      end
      
      # Shard count in word 1 isn't reliable.
      # Better is to take the start of the first shard - the preamble divided by the descriptor size
      def shard_count
        [words[1].half_word[1].to_i, (words[content_offset + 5 + 7] - 5).div(File::Frozen::Descriptor.size)].min
      end
      
      def update_date
        File.date(_update_date)
      end
  
      def _update_date
        characters[2*characters_per_word, 8].join
      end
    
      def update_time_of_day
        File.time_of_day(_update_time_of_day)
      end
    
      def _update_time_of_day
        words[4]
      end
    
      # TODO Choose earlier of update time or time indicated in index
      def update_time
        File.time(_update_date, _update_time_of_day)
      end
    
      def shard_descriptors
        @shard_descriptors ||= _shard_descriptors
      end
    
      def _shard_descriptors
        (0...shard_count).map do |i|
          Frozen::Descriptor.new(self, i)
        end
      end
      private :_shard_descriptors
    
      def shard_descriptor(n)
        shard_descriptors[n]
      end
    
      def file_size
        content_offset + shard_descriptor(shard_count-1).start + shard_descriptor(shard_count-1).size
      end
    
      def shard_name(n)
        d = shard_descriptor(n)
        return nil unless d
        d.name
      end
    
      def shard_names
        (0...shard_count).map{|n| shard_name(n)}
      end
    
      def shard_path(n=nil)
        d = shard_descriptor(n)
        return nil unless d
        d.path
      end
    
      def shard_paths
        (0...shard_count).map{|n| shard_path(n)}
      end
    
      # Convert a file name to an index number; also convert negative indexes
      # Allowed formats:
      # Numeric: Any integer. 1..<# shard_count> or -<# shard_count>..-1 (counting backwards)
      # String:  [+-]\d+ : same as an Integer (Use leading '+' to ensure non-ambiguity -- '+1' is the
      #                    first file, '1' is the file named '1')
      #          Other:    Name of file. Ignore leading '\\' if any -- this allows a way to specify
      #                    a file name starting with '+', as for instance '+OneForParty'
      def fn(n)
        if n.is_a?(Numeric) || n.to_s =~ /^[+-]\d+$/
          orig_n = n
          n = n.to_i if n.is_a?(String)
          n += shard_count+1 if n<0
          abort "Frozen file does not contain file number #{orig_n}" if n<1 || n>shard_count
          n -= 1
        else
          name = n.to_s.sub(/^\\/,'') # Remove leading '\\', if any
          n = shard_index(name)
          abort "Frozen file does not contain a file #{name}" unless n
        end
        n
      end
    
      def shard_index(name)
        descr = shard_descriptors.find {|d| d.name == name}
        if descr
          index = descr.number
        else
          index = nil
        end
        index
      end
    
      def shard_words(n)
        d = shard_descriptor(n)
        return nil unless d
        if n == shard_count-1
          words[d.start..-1]
        else
          words[d.start, d.size]
        end
      end
    
      def shards
        @shards ||= _shards
      end
    
      def _shards
        (0...shard_count).map {|i| _shard(i)}
      end
      private :_shards
    
      def shard(n)
        @shards ||= []
        @shards[n] ||= _shard(n)
      end
    
      def _shard(n)
        lines(n).map{|l| l[:content]}.join
      end
      private :_shard
    
      def shard_lines
        @shard_lines ||= _shard_lines
      end
    
      def _shard_lines
        (0...shard_count).map {|i| _lines(i)}
      end
      private :_shard_lines
    
      def lines(n)
        @shard_lines ||= []
        @shard_lines[n] ||= thaw(n)
      end

      def thaw(n)
        words = shard_words(n)
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
            lines << {:content=>line, :content_offset=>line_offset, :shard_descriptor=>words[line_offset], 
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
        content_offset = line_offset
        okay = true
        loop do
          word = words[content_offset]
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
          content_offset += 1
        end
        return [content_offset, nil, false] unless line =~ /\r/
        [content_offset, line, okay]
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
end
require 'gecos/file/freezer_descriptor'