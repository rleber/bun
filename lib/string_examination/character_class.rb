#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Abstract base class for counting classes of characters

require 'lib/string_examination/analysis_base'

class String
  class Examination
    # Abstract base class
    # Subclasses need to define patterns
    class CharacterClass < AnalysisBase
      
      def pattern_hash
        self.class.const_get('PATTERN_HASH')
      end
      
      def categories
        pattern_hash.keys
      end
      
      def fields
        %w{Category Characters Count}
      end
      
      def patterns
        pattern_hash.values
      end
      
      def initialize(string='')
        super(string, patterns)
      end
      
      def counts
        super.to_a.map.with_index do |row, i|
          row.merge(category: categories[i])
        end
      end
      
      def analysis
        counts.reject {|row| row[:count] == 0 }
        .sort_by{|row| -row[:count]}
      end
      
      # These format methods can be overridden in subclasses
      def format_category(row)
        row[:category].to_s.gsub(/non_/i,'non-').gsub('_',' ').titleize
      end
      
      def format_character_set(row)
        row[:characters].keys.join.character_set
      end
      
      def format_count(row)
        row[:count].to_s
      end
      
      def format_row(row)
        [
          format_category(row),
          format_character_set(row),
          format_count(row)
        ]
      end
      
      def formatted_table
        [fields] + analysis.map {|row| format_row(row) }
      end
      
      def justified
        tbl = formatted_table
        tbl.justify_rows(right_justify: [tbl.first.size-1])
      end
      
      def rows
        justified.map{|row| row.join('  ')}
      end
      
      def to_s
        rows.join("\n")
      end
    end
  end
end
