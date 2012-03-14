require 'slicr'

WIDTH = 36

class TestWord < Slicr::Word
  width WIDTH
  
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
    cached
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
  end
end

class TestWords < Slicr::Words(TestWord)
end

class StrangeWord < Slicr::Word
  width WIDTH
  
  slice :too_long, :width=>WIDTH+1
end

class TestWordOnes < Slicr::Word
  width WIDTH
  
  field :integer do
    width WIDTH
    sign :ones_complement
  end
end

