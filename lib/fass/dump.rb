class Fass
  class Dump
    def self.dump(words, options={})
      limit = options[:lines]
      offset = options[:offset] || 0
      decoder = Decoder.new(nil)
      decoder.words = words
      if options[:frozen]
        characters = decoder.frozen_characters
        character_block_size = 20
      else
        characters = decoder.characters
        character_block_size = 16
      end
      address_width = ('%o'%(words.size)).size
      ((words.size+3).div 4).times do |i|
        next if i < offset
        chunk = ((words[i*4, 4].map{|w| '%012o'%w }) + ([' '*12] * 4))[0,4]
        chars = characters[i*character_block_size, character_block_size].gsub(/[[:cntrl:]]/, '~')
        chars = (chars + ' '*character_block_size)[0,character_block_size]
        address = "%0#{address_width}o"%(i*4)
        puts "#{address} #{chunk.join(' ')} #{chars}"
        if limit
          break if i >= (offset + limit-1)
        end
      end
    end
  end
end