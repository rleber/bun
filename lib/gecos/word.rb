require 'machine'

require 'pp'
class GECOS
  class Word < Machine::Word
    WIDTH = 36
    width WIDTH
    
    # TODO Is there a less kludgy way to do this?
    def inspect
      "<#{self.class} #{'%012o' % internal_value}>"
    end
    define_format :default, :octal
    
    slice :half_word, :width=>width/2
    slice :byte, :width=>9
    
    slice :character do
      width 9
      bits 7
      string
    end
    
    slice :packed_character do
      width 7
      offset 1
      string
    end
    
    slice :bit do
      width 1
    end

    field :integer do
      width WIDTH
      sign :twos_complement
      format :decimal, '%d'
      format :default, :decimal
    end

    field :sign do
      width 1
    end

    field :low_byte do
      width 9
      offset 27
    end

    field :upper_half_word do
      width 18
    end

    field :lower_half_word do
      width 18
      offset 18
    end
  end
  
  class Words < Machine::Words(GECOS::Word)
  end
  
  # TODO Test this out
  class Block < Machine::Block(GECOS::Word)
    slice :word_and_a_half, :width=>(word_size*3).div(2)
  end
end  
