#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Calculate proportion of readable vs. non-readable characters

require 'lib/trait/numeric'

class String
  class Trait
    class Legibility < String::Trait::Numeric
      
      READABLE_CATEGORIES = %w{text digits punctuation control}.map{|c| c.to_sym}
      
      def self.description
        "Calculate proportion of readable characters"
      end
      
      def analysis
        counts = String::Trait.examine(string, :classes)
        total_count = counts.map{|row| row[:count]}.sum
        readable_count = counts.select{|row| READABLE_CATEGORIES.include?(row[:category])} \
                         .map{|row| row[:count]}.sum
        readable_count*1.0 / total_count
      end
      
      def format(x)
        '%0.2f%' % (x*100.0)
      end
    end
  end
end
