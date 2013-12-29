#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Class to calculate proportion of english vs. non-english characters

class String
  class Check
    class English < Base
      
      def english_proportion
        counts = String::Analysis.analyze(string, :classes)
        total_count = counts.map{|row| row[:count]}.sum
        english_count = counts.select{|row| [:text, :digits, :punctuation].include?(row[:category])} \
                        .map{|row| row[:count]}.sum
        english_count*1.0 / total_count
      end
      
      def check
        english_proportion
      end
      
      def to_s
        '%0.2f%' % (check*100.0)
      end
    end
  end
end
