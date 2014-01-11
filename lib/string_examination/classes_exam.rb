#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Count major classes of characters (e.g. text, digits, punctuation)

require 'lib/string_examination/character_class'

class String
  class Examination
    class Classes < CharacterClass
      
      # TODO Refactor using POSIX classes, e.g. /[[:digit:]]/
      TEXT_CHARACTERS = 'a-zA-Z'
      DIGITS = '0-9'
      PUNCTUATION_CHARACTERS = '\.,(){}\[\]:;\-\'"! \\\\#$%&*+/<=>?@^_`|~'
      VALID_CONTROL_CHARACTERS = String.const_get('VALID_CONTROL_CHARACTERS')
      PATTERN_HASH = {
        text: /[#{TEXT_CHARACTERS}]/,
        digits: /[#{DIGITS}]/,
        punctuation: /[#{PUNCTUATION_CHARACTERS}]/,
        control: /[#{VALID_CONTROL_CHARACTERS}]/,
        other: /[^#{TEXT_CHARACTERS}#{DIGITS}#{PUNCTUATION_CHARACTERS}#{VALID_CONTROL_CHARACTERS}]/,
      }
      
      def self.description
        "Count major classes of characters"
      end
    end
  end
end