#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

module Bun
  class File < ::File
    class Frozen < Bun::File::Unpacked
      include CacheableMethods
      
      class << self
        def open(path, options={}, &blk)
          File::Unpacked.open(path, options.merge(:type=>:frozen), &blk)
        end
      end
      
      attr_reader :file
      attr_accessor :status
      attr_accessor :warn
    
      # TODO do we ever instantiate a File::Frozen without a new file? If not, refactor
      def initialize(options={})
        options[:data] = Data.new(options) if options[:data] && !options[:data].is_a?(Bun::Data)
        super
        # TODO Why is file_date necessary?
        descriptor.register_fields(:shards, :file_time)
        @warn = options[:warn]
      end
      
      # This is the official definition. Even though some other approaches might be more reliable,
      # they're either slow or awkwardly recursive
      def shard_count
        shard_count_based_on_word_1
      end
      
      # There are three ways to determine shard count. The first of these is the official way: it is
      # fast but relies on a header data field being set correctly. The second is also fast, and should
      # work unless the shard data is in the wrong place, which seems unlikely. The third is the most 
      # reliable -- it counts the shard describtors -- but it's slower.
      
      # Official method: fast, and reliable if the field is set properly
      def shard_count_based_on_word_1
        words.at(content_offset+1).half_words.at(1).to_i
      end

      # Fast and fairly reliable, but awkwardly recursive:
      def shard_count_based_on_position_of_shard_contents
        descriptors_size.div(File::Frozen::Descriptor.size)
      end
      
      # Most reliable, but slower:
      def shard_count_based_on_count_of_valid_shard_descriptors
        i = 0
        loop do
          d = Frozen::Descriptor.new(self, i, :allow=>true)
          break if !d.valid?
          i += 1
        end
        i
      end
      
      # TODO reimplement this based on LazyArray for descriptors
      def preamble_size
        # Find size from position of data for first shard
        words.at(content_offset + File::Frozen::Descriptor.offset + 7).to_i
      end
      
      def header_size
        content_offset + preamble_size
      end
      
      def descriptors_size
        preamble_size - File::Frozen::Descriptor.offset
      end
      
      def file_date
        File::Unpacked.date(_update_date)
      end
      
      # Reference to all_characters is necessary here, because characters isn't
      # available in header files. Still, it seems a bit kludgy...
      def _update_date
        all_characters[(content_offset + 2)*characters_per_word, 8].join
      end
    
      def update_time_of_day
        File::Unpacked.time_of_day(_update_time_of_day)
      end
    
      def _update_time_of_day
        words.at(content_offset + 4)
      end
    
      def file_time
        Bun::Data.time(_update_date, _update_time_of_day)
      end
    
      def shard_descriptors
        descriptor.shards.map.with_index {|d,i| Hashie::Mash.new(d.merge(:number=>i)) }
      end
      cache :shard_descriptors
      
      def shard_descriptor_hashes
        shard_descriptors.map{|d| d.to_hash }
      end
    
      def shard_descriptor(n)
        shard_descriptors.at(shard_index(n))
      end
    
      def tape_size
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
    
      # Convert a shard name or number to an index number; also convert negative indexes
      # Allowed formats:
      # Numeric: Any integer. 0..<# shard_count> or -<# shard_count>..-1 (counting backwards)
      # String:  [+-]\d+ : same as an Integer (Use leading '+' to ensure non-ambiguity -- '+1' is the
      #                    second file, '1' is the file named '1')
      #          Other:    Name of file. Ignore leading '\\' if any -- this allows a way to specify
      #                    a file name starting with '+', as for instance '+OneForParty'
      def shard_index(n)
        orig_n = n
        n = n.to_i if n.is_a?(GenericNumeric)
        if n.is_a?(Numeric) || n.to_s =~ /^[+-]\d+$/
          n = n.to_i if n.is_a?(String)
          n += shard_count if n<0
          stop "Frozen file does not contain shard number #{orig_n}" if n<0 || n>shard_count
        else
          name = n.to_s.sub(/^\\/,'') # Remove leading '\\', if any
          raise "!Missing shard index or name" if n.to_s == '' # debug
          n = _shard_index(name)
          stop "!Frozen file does not contain a shard named #{name.inspect}" unless n
        end
        n
      end
    
      def _shard_index(name)
        descr = shard_descriptors.find {|d| d.name == name}
        if descr
          index = descr.number
        else
          index = nil
        end
        index
      end
      private :_shard_index
      
      def shard_extent(n)
        d = shard_descriptor(n)
        return nil unless d
        [d.start+content_offset, d[:size]]
      end
      
      # def shard_data(n)
      #   d = shard_descriptor(n)
      #   return nil unless d
      #   data.subset(d.start + content_offset, d.tape_size)
      # end
    
      def shard_words(n)
        d = shard_descriptor(n)
        return nil unless d
        words[d.start + content_offset, d[:size]]
      end
      
      def shards
        s = []
        shard_count.times do |i|
          text = shard_lines.at(i).map{|l| l[:content]}.join
          # shard_descriptors.at(i).control_characters = File.control_character_counts(text)
          shard_descriptors.at(i).character_count    = text.size
          s << text
        end
        s
      end
    
      def shard_lines
        LazyArray.new(shard_count) {|i| thaw(i) }
      end

      def thaw(n)
        words = shard_words(n)
        line_offset = 0
        lines = []
        warned = false
        shard_descriptor(n).status = :readable
        while line_offset < words.size
          last_line_word, line, okay = thaw_line(n, words, line_offset)
          if !line
            if lines.size == 0
              shard_descriptor(n).status = :unreadable
            else
              shard_descriptor(n).status = :truncated
            end
            Kernel.warn "Bad lines corrected" if !warned && @warn
            warned = true
            break
          else
            raw_line = line
            line.sub!(/\r\0*$/,"\n")
            lines << {:content=>line, :content_offset=>line_offset, :shard_descriptor=>words.at(line_offset), 
                      :words=>words[line_offset..last_line_word], :raw=>raw_line}
            line_offset = last_line_word + 1
          end
        end
        lines
      end
    
      # TODO Refactor like File::Text#unpack_line
      def thaw_line(n, words, line_offset)
        line = ""
        line_length = words.size
        content_offset = line_offset
        okay = true
        loop do
          word = words.at(content_offset)
          break unless word
          ch_count = 5
          if line==""
            if good_descriptor?(word)
              line_length = line_length(word)
              ch_count = 3
            else
              error "Shard #{n}: Bad descriptor at #{content_offset}: #{word.inspect}"
              okay = false
            end
          end
          chs = decode_characters(word, ch_count)
          if chs =~ /^(.*\r).*$/
            line += $1
            break
          end
          line += chs
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
    
      def decode_characters(word, n=5)
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
      
      def decoded_text(options={})
        content = shards.at(shard_index(options[:shard]))
      end
      
      def to_hash(options=[])
        base_hash = super(options)
        base_hash.delete(:shards)
        index = shard_index(options[:shard])
        shard_descriptor = descriptor.shards[index].to_a.inject({}) do |hsh, pair|
          key, value = pair
          new_key = "shard_#{key.to_s.sub(/^file_/,'')}".to_sym
          hsh[new_key] = value
          hsh
        end
        base_hash.merge(shard_number: index).merge(shard_descriptor)
      end
    end
  end
end
require 'lib/bun/file/frozen_descriptor'