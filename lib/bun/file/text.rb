#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

module Bun
  class File < ::File
    class Text < Bun::File::Blocked
      include CacheableMethods
      
      attr_accessor :keep_deletes
      attr_reader   :control_characters, :character_count
    
      # TODO do we ever instantiate a File::Text without reading a file? If not, refactor
      def initialize(options={})
        @keep_deletes = options[:keep_deletes]
        options[:data] = Data.new(options) if options[:data] && !options[:data].is_a?(Bun::Data)
        super
        # descriptor.register_fields(:control_characters, :character_count)
        # @control_characters = nil
        # @character_count = nil
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
        @control_characters = File.control_character_counts(res)
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
      
      def extract(to, options={})
        self.keep_deletes = options[:delete]
        content = options[:inspect] ? self.inspect : self.text
        shell = Shell.new
        shell.write to, content
        copy_descriptor(to, :extracted=>Time.now) unless options[:bare] || to.nil? || to=='-'
      end
    end
  end
end