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
      if options[:limit]
        limit = options[:limit]
        limit = words.size - 1 if limit >= words.size
      elsif options[:lines]
        limit = (options[:lines] * WORDS_PER_LINE - 1) + offset
        limit = words.size - 1 if limit >= words.size
      else 
        limit = words.size - 1
      end
      bit_offsets = options[:bit_offsets] || [0]
      display_offset = (options[:display_offset] || offset) - offset
      stream = options[:to] || STDOUT
      limit = [limit, data.size-1].min unless options[:unlimited]
      if options[:frozen]
        characters = data.all_packed_characters
        character_block_size = FROZEN_CHARACTERS_PER_WORD
      else
        characters = data.all_characters
        character_block_size = UNFROZEN_CHARACTERS_PER_WORD
      end
      # TODO Refactor using Array#justify_rows
      address_width = ('%o'%(limit+display_offset)).size
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
        chars = (chars + ' '*(WORDS_PER_LINE*character_block_size))[0,WORDS_PER_LINE*character_block_size]
        if options[:escape]
          chars = chars.inspect[1..-2].scan(/\\\d{3}|\\[^\d\\]|\\\\|[^\\]/).map{|s| (s+'   ')[0,4]}.join
        else
          chars = chars.gsub(/[[:cntrl:]]/, '~')
          chars = chars.gsub(/_/, '~').gsub(/\s/,'_') unless options[:spaces]
          chars = chars.scan(/.{1,#{character_block_size}}/).join(' ')
        end
        address = '0' + ("%0#{address_width}o"%(i + display_offset))
        stream.puts "#{address} #{chunk.join(' ')} #{chars}"
        line_count += 1
        i += WORDS_PER_LINE
      end
      line_count
    end
  end
end