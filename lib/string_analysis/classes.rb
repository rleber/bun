#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Classes to define analysis of major classes of characters

class String
  class Analysis
    class Classes < CharacterClass
      
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
      
      def description
        "Count major classes of characters"
      end
    end
  end
end
