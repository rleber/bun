#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

module Bun
  class File < ::File
    class Text < Bun::File::Blocked
      include CacheableMethods
      
      attr_accessor :keep_deletes
    
      # TODO do we ever instantiate a File::Text without reading a file? If not, refactor
      def initialize(options={})
        @keep_deletes = options[:keep_deletes]
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
        lines.map{|l| l[:content]}.join
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
        if descriptor == self.class.eof_marker
          return {:status=>:eof, :start=>line_offset, :finish=>size-1, :content=>nil, :raw=>nil, :words=>nil, :descriptor=>descriptor}
        elsif (descriptor >> 27) & 0777 == 0177
          raise "Deleted"
          deleted = true
          line_length = word_count
        elsif (descriptor >> 27) & 0777 == 0
            line_length = descriptor.half_word(0)
        else # Sometimes, there is ASCII in the descriptor word; In that case, capture it, and look for terminating "\177"
          raise "ASCII in descriptor"
        end
        offset = line_offset+1
        raw_line = words[offset,line_length].map{|w| w.characters}.join
        line = raw_line.sub(/\177+$/,'') + "\n"
        {:status=>(okay ? :okay : :error), :start=>line_offset, :finish=>line_offset+line_length, :content=>line, :raw=>raw_line, :words=>words.at(line_offset+line_length), :descriptor=>descriptor}
      end
    end
  end
end