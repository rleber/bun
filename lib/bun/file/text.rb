#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

module Bun
  class File < ::File
    class Text < Bun::File::Blocked
      include CacheableMethods

      class DeletedLineFound < RuntimeError; end
      class BadLineDescriptor < RuntimeError; end
      
      class << self
        def open(path, options={}, &blk)
          File::Unpacked.open(path, options.merge(:type=>:text), &blk)
        end
      end
      
      attr_accessor :keep_deletes, :strict
      attr_reader   :control_characters, :character_count
    
      # TODO do we ever instantiate a File::Text without reading a file? If not, refactor
      def initialize(options={})
        @keep_deletes = options[:keep_deletes]
        @strict = options[:strict]
        options[:data] = Data.new(options) if options[:data] && !options[:data].is_a?(Bun::Data)
        super
      end
    
      def words=(words)
        super
        if @words.nil?
          @text = @lines = nil
          clear_errors
        end
        words
      end
    
      def text
        res = lines.map{|l| l[:content]}.join
        @character_count = res.size
        res
      end
      cache :text
    
      def lines
        line_offset = 0
        lines = []
        warned = false
        n = 0
        while line_offset < content.size
          line = unpack_line(content, line_offset)
          line[:status] = :ignore if n==0
          case line[:status]
          when :eof     then break
          when :okay    then lines << line
          when :delete  then lines << line if @keep_deletes
          when :ignore  then # do nothing
          end
          line_offset = line[:finish]+1
          n += 1
        end
        lines
      end
      cache :lines
    
      # TODO simplify
      def unpack_line(words, line_offset)
        line = ""
        raw_line = ""
        okay = true
        descriptor = words.at(line_offset)
        if descriptor == eof_marker
          return {:status=>:eof, :start=>line_offset, :finish=>data.size-1, :content=>nil, :raw=>nil, :words=>nil, :descriptor=>descriptor}
        elsif (descriptor >> 27) & 0777 == 0177
          # raise DeletedLineFound, "Deleted line at #{line_offset}(0#{'%o'%line_offset})"
          deleted = true
          line_length = descriptor.half_word(0)
        elsif (descriptor >> 27) & 0777 == 0
          line_length = descriptor.half_word(0)
        else # Sometimes, there is ASCII in the descriptor word; In that case, capture it, and look for terminating line descriptor
          line_offset -= 1 # Back up so the descriptor word is included in the line we're trying to find
          new_line_offset = find_next_line(words, line_offset+2) # Start looking in the second word of the line
          unless new_line_offset
            raise BadLineDescriptor, "Bad line at #{line_offset}(0#{'%o'%line_offset}): " + 
                                  "#{'%013o'%descriptor} #{descriptor.characters.join.inspect}"
          end
          line_length = new_line_offset - line_offset - 1
        end
        offset = line_offset+1
        raw_line = words[offset,line_length].map{|w| w.characters}.join
        line = raw_line.sub(/\177+$/,'') + "\n"
        {:status=>(okay ? :okay : :error), :start=>line_offset, :finish=>line_offset+line_length, :content=>line, :raw=>raw_line, :words=>words.at(line_offset+line_length), :descriptor=>descriptor}
      end
      
      # TODO Is this necessary any more?
      def inspect
        inspect_lines = []
        self.lines.each do |l|
          start = l[:start]
          line_descriptor = l[:descriptor]
          line_length = line_descriptor.half_word[0]
          line_flags = line_descriptor.half_word[1]
          line_codes = []
          line_codes << 'D' if l[:status]==:deleted
          line_codes << '+' if line_length > 0777 # Upper bits not zero
          line_codes << '*' if (line_descriptor & 0777) != 0600 # Bottom descriptor byte is normally 0600
          inspect_lines << %Q{#{"%06o" % start}: len #{"%06o" % line_length} (#{"%6d" % line_length}) [#{'%06o' % line_flags} #{'%-3s' % (line_codes.join)}] #{l[:raw].inspect}}
        end
        inspect_lines.join("\n")
      end

      def media_codes
        self.lines.inject([]) do |ary, line|
          flags = line_flags(line)
          ary << flags[:media_code]
        end.compact.uniq.sort
      end

      def multi_segment
        self.lines.any? {|line| flags = line_flags(line); flags[:segment_marker]>0}
      end

      def line_flags(line)
        descriptor = line[:descriptor]
        length = descriptor.half_word[0].to_i
        flags  = descriptor.half_word[1].to_i
        if length == 0
          eof_type = (flags>>12) & 017
        else
          eof_type = nil
        end
        segment_marker = (flags>>10) & 03
        if segment_marker < 2
          @last_media_code = media_code = (flags>>6) & 017
          @last_report_code = report_code = flags & 077
          segment_number = 0
        else
          media_code = @last_media_code
          report_code = @last_report_code
          segment_number = flags & 01777
        end
        if media_code == 4 || media_code == 6
          final_bytes = flags>>16
          byte_count = length*4 + final_bytes - 4
        else
          byte_count = final_bytes = nil
        end
        {
          eof_type: eof_type,
          length: length, 
          byte_count: byte_count,
          segment_marker: segment_marker, 
          segment_number: segment_number,
          media_code: media_code,
          report_code: report_code,
        }
      end
      
      def decoded_text(options={})
        self.keep_deletes = options[:delete]
        options[:inspect] ? self.inspect : self.text
      end

      def find_next_line(words, line_offset)
        loop do
          break if line_offset >= words.size
          w = words.at(line_offset)
          break if w == eof_marker
          break if ((w>>27) & 0777 == 0) && (w & 0777 == 0600) # Line descriptor word
          return nil if @strict && w.bytes.any? {|b| b>255}
          line_offset += 1
        end
        line_offset
      end
    end
  end
end