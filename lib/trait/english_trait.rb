#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Calculate proportion of english words

require 'lib/trait/numeric'
require 'lib/trait/english_check.rb'

class String
  class Trait
    class English < String::Trait::Numeric
      include EnglishCheck
      
      def self.description
        "Calculate proportion of english words"
      end

      def analysis
        word_counts = String::Trait.examine(string, :words)
        total_count = word_counts.map{|row| row[:count]}.sum
        english_count = word_counts.select{|row| is_english?(row[:word])} \
                         .map{|row| row[:count]}.sum
        english_count*1.0 / total_count
      end
      
      def fmt(x)
        '%0.2f%' % (x*100.0)
      end
    end
  end
end
