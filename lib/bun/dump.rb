#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

module Bun
  class Dump
    
    WORDS_PER_LINE = 4
    FROZEN_CHARACTERS_PER_WORD = 5
    UNFROZEN_CHARACTERS_PER_WORD = 4
    
    # TODO Dump should understand frozen file sizes
    # TODO Dump should be able to dump frozen file preambles 4 chars/word, then 5 chars/word for the remainder
    # TODO Should dump be part of Words?
    def self.dump(data, options={})
      words = data.words
      offset = options[:offset] || 0
      if options[:length]
        limit = options[:length] + offset - 1
        limit = words.size - 1 if limit >= words.size
      elsif options[:lines]
        limit = (options[:lines] * WORDS_PER_LINE - 1) + offset
        limit = words.size - 1 if limit >= words.size
      else 
        limit = words.size - 1
      end
      bit_offsets = options[:bit_offsets] || [0]
      display_offset = (options[:display_offset] || offset) - offset
      stream = options[:to] || $stdout
      if options[:frozen]
        characters = data.all_packed_characters
        character_block_size = FROZEN_CHARACTERS_PER_WORD
      else
        characters = data.all_characters
        character_block_size = UNFROZEN_CHARACTERS_PER_WORD
      end
      indent = options[:indent] || 0
      pad = ' '*indent
      # TODO Refactor using Array#justify_rows
      address_width = options[:address_width] || ('%o'%(limit+display_offset)).size+1
      i = offset
      line_count = 0
      loop do
        break if i > limit
        j = [i+WORDS_PER_LINE-1, limit].min
        chunk = words[i..j]
        chars = characters[i*character_block_size, chunk.size*character_block_size]
        if chars.nil?
          puts "Nil chars:\ni=#{i}, j=#{j}, chunk=#{chunk.inspect}"
        end
        chars = chars.join
        chunk = ((chunk.map{|w| '%012o'%w }) + ([' '*12] * WORDS_PER_LINE))[0,WORDS_PER_LINE]
        if options[:escape]
          chars = (chars + ' '*(WORDS_PER_LINE*character_block_size))[0,WORDS_PER_LINE*character_block_size]
          chars = chars.inspect[1..-2].scan(/\\\d{3}|\\[^\d\\]|\\\\|[^\\]/).map{|s| (s+'   ')[0,4]}.join
        else
          chars = chars.gsub(/[[:cntrl:]]/, '~')
          chars = chars.gsub(/_/, '~').gsub(/\s/,'_') unless options[:spaces]
          chars = (chars + ' '*(WORDS_PER_LINE*character_block_size))[0,WORDS_PER_LINE*character_block_size]
          chars = chars.scan(/.{1,#{character_block_size}}/).join(' ')
        end
        address = "%0#{address_width}o" % (i + display_offset)
        stream.puts "#{address}#{pad} #{chunk.join(' ')} #{chars}"
        line_count += 1
        i += WORDS_PER_LINE
      end
      line_count
    end

    def self.structured_dump(data, options={})
      stream = options[:to] || $stdout
      offset = options[:offset] || 0
      display_offset = (options[:display_offset] || offset) - offset
      indent = options[:indent] || 0
      pad = ' '*indent
      if options[:length]
        limit = options[:length] + offset - 1
        limit = data.words.size - 1 if limit >= data.words.size
      else 
        limit = data.words.size - 1
      end
      address_width = options[:address_width] || ('%o' % (display_offset+limit)).size+1
      lc = 0
      dump_options = options.merge(address_width: address_width, indent: indent+2)
      i = 0
      loop do
        dump_options.merge!(link_count: i)
        offset, lc_incr, eof = dump_link(data, offset, dump_options)
        lc += lc_incr
        break if eof
        break if options[:lines] && lc >= options[:limit]
        break if offset >= limit
        i += 1
      end
      lc
    end

    def self.dump_link(data, offset, options={})
      stream = options[:to] || $stdout
      display_offset = (options[:display_offset] || offset) - offset
      indent = options[:indent] || 0
      pad = ' '*indent
      bcw = data.words.at(offset)
      link_number = bcw.half_word[0].to_i
      link_length = bcw.half_word[1].to_i
      link_limit = offset + link_length
      address_width = options[:address_width] || ('%o' % (display_offset+link_limit)).size+1
      address = "%0#{address_width}o" % (offset + display_offset)
      stream.puts "#{address}#{pad} LINK #{'%013o'%bcw} ##{link_number} words #{link_length}"
      lc = 1
      offset += 1
      return [offset, 0, true] unless link_length > 0
      eof = false
      dump_options = options.merge(address_width: address_width, indent: indent+2)
      offset, lc_incr = dump_preamble(data, offset, dump_options)
      lc += lc_incr
      case data.type
      when :frozen
        if options[:link_count] == 0
          shard_count = data.words.at(offset+1).to_i
          offset, lc_incr, eof = dump_frozen_information_block(data, offset, dump_options)
          lc += lc_incr
          shard_count.times do |shard_index|
            offset, lc_incr, eof = dump_frozen_shard_descriptor(data, offset, dump_options)
            lc += lc_incr
          end
        end
        offset, lc_incr, eof = dump_frozen_link(data, offset, dump_options.merge(link_limit: link_limit))
        lc += lc_incr
      when :text
        loop do
          break if offset >= link_limit
          offset, lc_incr, eof = dump_llink(data, offset, dump_options)
          lc += lc_incr
          break if eof
        end
      else
        stop "!Can't dump #{data.type} files"
      end
      [offset, lc, eof]
    end

    def self.dump_preamble(data, offset, options={})
      stream = options[:to] || $stdout
      display_offset = (options[:display_offset] || offset) - offset
      indent = options[:indent] || 0
      pad = ' '*indent
      bcw = data.words.at(offset)
      preamble_flags = bcw.half_word[0].to_i
      preamble_size = bcw.half_word[1].to_i
      content_start = offset + preamble_size - 1
      address_width = options[:address_width] || ('%o'%(content_start-1+display_offset)).size+1
      address_mask = "%0#{address_width}o"
      address = address_mask % (offset + display_offset)

      stream.puts "#{address}#{pad} PREAMBLE #{'%013o'%bcw} flags #{'%07o' % preamble_flags} content_start #{address_mask % content_start}"
      lc = 1
      lc += dump(data, options.merge(offset: offset+1, length: preamble_size-2, indent: indent+2, address_width: address_width))
      [content_start, lc]
    end

    def self.dump_llink(data, offset, options={})
      stream = options[:to] || $stdout
      display_offset = (options[:display_offset] || offset) - offset
      indent = options[:indent] || 0
      pad = ' '*indent
      address_width = options[:address_width] || ('%o' % (display_offset+319)).size+1
      bcw = data.words.at(offset)
      llink_number = bcw.half_word[0].to_i
      llink_length = bcw.half_word[1].to_i
      llink_limit = offset + 1 + llink_length
      next_llink = offset + 320
      address = "%0#{address_width}o" % (offset + display_offset)
      stream.puts "#{address}#{pad} LLINK #{'%013o'%bcw} ##{llink_number} words #{llink_length}"
      lc = 1
      offset += 1
      return [offset, 0, true] unless llink_length > 0
      eof = false
      loop do
        break if offset >= llink_limit
        offset, lc_incr, eof = dump_record(data, offset, options.merge(address_width: address_width, indent: indent+2))
        lc += lc_incr
        break if eof
      end
      [next_llink, lc, eof]
    end

    def self.dump_record(data, offset, options={})
      stream = options[:to] || $stdout
      display_offset = (options[:display_offset] || offset) - offset
      indent = options[:indent] || 0
      pad = ' '*indent
      descriptor = data.words.at(offset)
      flags = File::Text.line_flags(descriptor)
      address_width = options[:address_width] || ('%o'%(flags[:length]+display_offset)).size+1
      address = "%0#{address_width}o" % (offset + display_offset)
      stream.puts "#{address}#{pad} #{format_rcw(descriptor)}"
      lc = 1
      lc += dump(data, options.merge(offset: offset+1, length: flags[:length], indent: indent+2, address_width: address_width)) \
        unless flags[:eof]
      [offset+flags[:length]+1, lc, flags[:eof]]
    end

    def self.format_rcw(rcw)
      flags = File::Text.line_flags(rcw)
      segments = ["RCW #{'%013o'%rcw}"]
      if flags[:eof]
        segments << "EOF #{flags[:eof_type]}" if flags[:eof]
      else
        segments << "deleted" if flags[:deleted]
        segments << "top_byte #{'%07o'%flags[:top_byte]}" unless flags[:top_byte]==0
        segments << "media_code #{flags[:media_code]}"
        segments << "report_code #{flags[:report_code]}" unless flags[:report_code]==0
        if flags[:segment_marker] != 0
          segments << "segment_marker #{flags[:segment_marker]}"
          segments << "segment_number #{flags[:segment_number]}"
        end
        segments << "words #{flags[:length]}"
        segments << "bytes #{flags[:bytes]}"
        segments << "(final_bytes #{flags[:final_bytes]})" unless flags[:final_bytes]==4 || flags[:final_bytes]==flags[:bytes]
      end
      segments.join(' ')
    end

    def self.dump_frozen_information_block(data, offset, options={})
      stream = options[:to] || $stdout
      display_offset = (options[:display_offset] || offset) - offset
      indent = options[:indent] || 0
      pad = ' '*indent
      address_width = options[:address_width] || ('%o'%(offset+5+display_offset)).size+1
      address = "%0#{address_width}o" % (offset + display_offset)
      stream.puts "#{address}#{pad} FIB"
      lc = 1
      lc += dump(data, options.merge(offset: offset, length: 5, indent: indent+2, address_width: address_width))
      [offset+5, lc, false]
    end

    def self.dump_frozen_shard_descriptor(data, offset, options={})
      stream = options[:to] || $stdout
      display_offset = (options[:display_offset] || offset) - offset
      indent = options[:indent] || 0
      pad = ' '*indent
      address_width = options[:address_width] || ('%o'%(offset+10+display_offset)).size+1
      address = "%0#{address_width}o" % (offset + display_offset)
      stream.puts "#{address}#{pad} SHARD_INDEX"
      lc = 1
      lc += dump(data, options.merge(offset: offset, length: 10, indent: indent+2, address_width: address_width))
      [offset+10, lc, false]
    end

    def self.dump_frozen_link(data, offset, options={})
      stream = options[:to] || $stdout
      display_offset = (options[:display_offset] || offset) - offset
      indent = options[:indent] || 0
      pad = ' '*indent
      link_limit = options[:link_limit]
      address_width = options[:address_width] || ('%o'%(link_limit+display_offset)).size+1
      address = "%0#{address_width}o" % (offset + display_offset)
      stream.puts "#{address}#{pad} CONTENT"
      lc = 1
      lc += dump(data, options.merge(offset: offset, length: link_limit-offset+1, frozen: true,
                                     indent: indent+2, address_width: address_width))
      [link_limit+1, lc, false]
    end
  end
end