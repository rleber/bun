#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# List non-english words

require 'lib/trait/numeric'
require 'lib/trait/english_check.rb'

class String
  class Trait
    class NonEnglishWords < CountTable
      include EnglishCheck
      
      def self.description
        "List non-english words"
      end
      
      def fields
        [:word, :count]
      end
      
      def analysis
        word_counts = String::Trait.examine(string, :words)
        word_counts.reject{|row| is_english?(row[:word])}
      end
    end
  end
end
