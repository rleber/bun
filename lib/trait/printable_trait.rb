#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Classes to define analysis of printable vs. non-printable characters

require 'lib/trait/character_class'

class String
  class Trait
    class Printable < CharacterClass
      
      PRINTABLE_CHARACTERS = 'a-zA-Z0-9\.,(){}\[\]:;\\-\'"! \\#$%&*+/<=>?@^_`|~\t\n\b\v\f\a\\\\'
      PATTERN_HASH = {
        printable: /[#{PRINTABLE_CHARACTERS}]/,
        non_printable: /[^#{PRINTABLE_CHARACTERS}]/
      }
      
      def self.description
        "Analyze printable vs. non-printable characters"
      end
    end
  end
end
