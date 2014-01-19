#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Abstract base class for counting classes of characters

require 'lib/examination/count_table'
require 'lib/examination/character_patterns'

class String
  class Examination
    # Abstract base class
    # Subclasses need to define patterns
    class CharacterClass < CountTable
      include CharacterPatterns
      
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
        @patterns ||= pattern_hash.values
      end
      
      def initialize(options={})
        super
      end
      
      def unfiltered_counts
        super.to_a.map.with_index do |row, i|
          row.merge(category: categories[i])
        end
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
