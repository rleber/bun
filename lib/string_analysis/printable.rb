#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Classes to define analysis of printable vs. non-printable characters

class String
  class Analysis
    class Printable < CharacterClass
      
      PRINTABLE_CHARACTERS = 'a-zA-Z0-9\.,(){}\[\]:;\-\'"! \\#$%&*+/<=>?@^_`|~\t\n\b\v\f\a'
      PATTERN_HASH = {
        printable: /[#{PRINTABLE_CHARACTERS}]/,
        non_printable: /[^#{PRINTABLE_CHARACTERS}]/
      }
      
      def description
        "Analyze printable vs. non-printable characters"
      end
    end
  end
end
