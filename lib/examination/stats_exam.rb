#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Calculate some statistics about the likelihood that this is an executable file

require 'lib/examination/character_class'

class String
  class Examination
    class Stats
      
      
      
      PRINTABLE_CHARACTERS = 'a-zA-Z0-9\.,(){}\[\]:;\-\'"! \\#$%&*+/<=>?@^_`|~\t\n\b\v\f\a'
      PATTERN_HASH = {
        printable: /[#{PRINTABLE_CHARACTERS}]/,
        non_printable: /[^#{PRINTABLE_CHARACTERS}]/
      }
      
      def self.description
        "Statistics about likelihood this is executable"
      end
    end
  end
end
