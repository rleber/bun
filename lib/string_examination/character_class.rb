#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Abstract base class for counting classes of characters

require 'lib/string_examination/count_table'

class String
  class Examination
    # Abstract base class
    # Subclasses need to define patterns
    class CharacterClass < CountTable
      
      def pattern_hash
        self.class.const_get('PATTERN_HASH')
      end
      
      def categories
        pattern_hash.keys
      end
      
      def fields
        [:category, :characters, :count]
      end
      
      def patterns
        pattern_hash.values
      end
      
      def initialize(string='')
        super(string, patterns)
      end
      
      def calculate_counts
        super.to_a.map.with_index do |row, i|
          row.merge(category: categories[i])
        end
      end
      
      def analysis
        counts.reject {|row| row[:count] <= (minimum||0) }
        .sort_by{|row| -row[:count]}
      end
      
      # These format methods can be overridden in subclasses
      def format_category(row)
        row[:category].to_s.gsub(/non_/i,'non-').gsub('_',' ').titleize
      end
      
      def format_characters(row)
        row[:characters].keys.join.character_set
      end
    end
  end
end
