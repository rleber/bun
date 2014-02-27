#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

require 'lib/slicr'

module Bun
  class Word < Slicr::Word
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

    slice :bcd do
      width 6
      string
    end

    class Bcd

      CHARACTER_SET = "0123456789[#\@:>? abcdefghi&.](<\\^jklmnopqr-$*);'+/stuvwxyz_,%=\"!"
      TRANSLATION_TABLE = CHARACTER_SET.split(//)

      def ascii_string
        TRANSLATION_TABLE[self.to_i]
      end
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

    def bcd_string
      self.bcds.map{|bcd| bcd.ascii_string }.join
    end
  end
  
  class Words < Slicr::Words(Bun::Word)
    def bcd_string
      map {|word| word.bcd_string}.join
    end
  end
end  