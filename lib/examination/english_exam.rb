#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Calculate proportion of english words

require 'lib/examination/numeric'
require 'lib/examination/english_check.rb'

class String
  class Examination
    class English < String::Examination::Numeric
      include EnglishCheck
      
      def self.description
        "Calculate proportion of english words"
      end

      def analysis
        word_counts = String::Examination.examine(string, :words)
        total_count = word_counts.map{|row| row[:count]}.sum
        english_count = word_counts.select{|row| is_english?(row[:word])} \
                         .map{|row| row[:count]}.sum
        english_count*1.0 / total_count
      end
      
      def format(x)
        '%0.2f%' % (x*100.0)
      end
    end
  end
end
