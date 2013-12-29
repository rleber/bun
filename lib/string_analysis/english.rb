#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Classes to define analysis of english vs. non-english characters

class String
  class Analysis
    class English < CharacterClass
      
      ENGLISH_CHARACTERS = 'a-zA-Z0-9\.,(){}\[\]:;\-\'"!'
      PATTERN_HASH = {
        english: /[#{ENGLISH_CHARACTERS}]/,
        non_english: /[^#{ENGLISH_CHARACTERS}]/
      }
      
      def description
        "Analyze english vs. non-english characters"
      end
    end
  end
end
