#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Calculate proportion of readable vs. non-readable characters

class String
  class Examination
    class Legibility < Base
      
      READABLE_CATEGORIES = %w{text digits punctuation control}.map{|c| c.to_sym}
      
      def self.description
        "Calculate proportion of readable characters"
      end
      
      def analysis
        counts = String::Examination.examination(string, :classes)
        total_count = counts.map{|row| row[:count]}.sum
        readable_count = counts.select{|row| READABLE_CATEGORIES.include?(row[:category])} \
                         .map{|row| row[:count]}.sum
        readable_count*1.0 / total_count
      end
      
      def to_s
        '%0.2f%' % (analysis*100.0)
      end
    end
  end
end
