#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Class to calculate proportion of readable vs. non-readable characters

class String
  class Check
    class Readability < Base
      
      READABLE_CATEGORIES = %w{text digits punctuation control}.map{|c| c.to_sym}
      
      def readable_proportion
        counts = String::Analysis.analyze(string, :classes)
        total_count = counts.map{|row| row[:count]}.sum
        readable_count = counts.select{|row| READABLE_CATEGORIES.include?(row[:category])} \
                         .map{|row| row[:count]}.sum
        readable_count*1.0 / total_count
      end
      
      def check
        readable_proportion
      end
      
      def to_s
        '%0.2f%' % (check*100.0)
      end
    end
  end
end
