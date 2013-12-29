#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Classes to define analysis of control characters

require 'lib/string'

class String
  class Analysis
    class Controls < CharacterClass
      
      CONTROL_CHARACTER_PATTERN_HASH = String.const_get('VALID_CONTROL_CHARACTER_HASH')
      INVALID_CHARACTER_PATTERN_HASH = { other: String.invalid_character_regexp }
      PATTERN_HASH = CONTROL_CHARACTER_PATTERN_HASH.merge(INVALID_CHARACTER_PATTERN_HASH)
      
      def description
        "Analyze control characters"
      end
    end
  end
end
