class Fass
  class Dump
    
    WORDS_PER_LINE = 4
    FROZEN_CHARACTERS_PER_WORD = 5
    UNFROZEN_CHARACTERS_PER_WORD = 4
    
    def self.dump(words, options={})
      offset = options[:offset] || 0
      if options[:lines]
        limit = (options[:lines] * WORDS_PER_LINE - 1) + offset
        limit = words.size - 1 if limit >= words.size
      else 
        limit = words.size - 1
      end
      display_offset = (options[:display_offset] || offset) - offset
      stream = options[:to] || STDOUT
      decoder = Decoder.new(nil)
      decoder.words = words
      if options[:frozen]
        characters = decoder.frozen_characters
        character_block_size = FROZEN_CHARACTERS_PER_WORD
      else
        characters = decoder.characters
        character_block_size = UNFROZEN_CHARACTERS_PER_WORD
      end
      address_width = ('%o'%(limit+display_offset)).size
      i = offset
      loop do
        break if i > limit
        j = [i+WORDS_PER_LINE-1, limit].min
        chunk = ((words[i..j].map{|w| '%012o'%w }) + ([' '*12] * WORDS_PER_LINE))[0,WORDS_PER_LINE]
        chars = characters[i*character_block_size, WORDS_PER_LINE*character_block_size]
        chars = (chars + ' '*(WORDS_PER_LINE*character_block_size))[0,WORDS_PER_LINE*character_block_size]
        if options[:escape]
          chars = chars.inspect[1..-2].scan(/\\\d{3}|\\[^\d\\]|\\\\|[^\\]/).map{|s| (s+'   ')[0,4]}.join
        else
          chars = chars.gsub(/[[:cntrl:]]/, '~')
        end
        address = '0' + ("%0#{address_width}o"%(i + display_offset))
        stream.puts "#{address} #{chunk.join(' ')} #{chars}"
        i += WORDS_PER_LINE
      end
    end
  end
end