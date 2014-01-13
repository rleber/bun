#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Count different control characters

require 'lib/examination/character_class'

class String
  class Examination
    class Controls < CharacterClass
      
      CONTROL_CHARACTER_PATTERN_HASH = String.const_get('VALID_CONTROL_CHARACTER_HASH')
      INVALID_CHARACTER_PATTERN_HASH = { other: String.invalid_character_regexp }
      PATTERN_HASH = CONTROL_CHARACTER_PATTERN_HASH.merge(INVALID_CHARACTER_PATTERN_HASH)
      
      def self.description
        "Count different control characters"
      end
    end
  end
end
