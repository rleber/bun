require 'machine'

class GECOS
  class Word < Machine::Word
    SIZE = 36
    size SIZE
    
    slice :half_word, :size=>size/2
    slice :byte, :size=>9
    
    slice :character do
      size 9
      bits 7
      string
    end
    
    slice :packed_character do
      size 7
      offset 1
      string
    end
    
    slice :bit do
      size 1
    end

    field :integer do
      size SIZE
      sign :twos_complement
      format :decimal, '%d'
      format :default, :decimal
    end

    field :sign do
      size 1
    end

    field :low_byte do
      size 9
      offset 27
    end

    field :upper_half_word do
      size 18
    end

    field :lower_half_word do
      size 18
      offset 18
    end
  end
  
  class Words < Machine::Words(GECOS::Word)
  end
  
  # TODO Test this out
  # class DoubleWords < Machine::Block(GECOS::Word)
  #   slice :word_and_a_half, :size=>word_size*3.div(2)
  # end
end  
