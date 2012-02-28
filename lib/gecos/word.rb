require 'machine'

class GECOS
  # TODO Make this more DSL-like
  class Word < Machine::Word
    define_size 36
    define_slice :half_word, :size=>size/2
    define_slice :byte, :size=>9
    define_slice :character, :size=>9, :bits=>7, :string=>true
    define_slice :packed_character, :size=>7, :offset=>1, :string=>true
    define_slice :bit, :size=>1
    define_slice :integer, :size=>size, :sign=>:twos_complement, :format=>{:decimal=>'%d'}, :default_format=>:decimal
    define_field :sign, :size=>1
    define_field :low_byte, :size=>9, :offset=>27
    define_field :upper_half_word, :size=>18
    define_field :lower_half_word, :size=>18, :offset=>18
  end
  
  class Words < Machine::Words(GECOS::Word)
  end
  
  class DoubleWords < Machine::MultiWord(GECOS::Word)
    define_slice :word_and_a_half, :size=>word_size*3.div(2)
  end
end  
