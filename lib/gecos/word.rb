require 'gecos/machine_word'

class Gecos
  class Word < MachineWord
    define_size 36
    # Define signed integer (useful for time values)
    define_slice :half_word, :size=>18
    define_slice :byte, :size=>9
    define_slice :character, :size=>9, :bits=>7, :string=>true
    define_slice :packed_character, :size=>7, :offset=>1, :string=>true
    define_slice :bit, :size=>1
  end
end  
