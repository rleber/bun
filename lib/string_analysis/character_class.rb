#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Abstract base classes for counting classes of characters

class String
  class Analysis
    # Abstract base class
    # Subclasses need to define patterns
    class CharacterClass < Base
      
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
      
      def data_table
        counts.reject {|row| row[:count] == 0 }
        .sort_by{|row| -row[:count]}
      end
      
      # This can be overridden in subclasses
      def format_row(row)
        [
          row[:category].to_s.gsub(/non_/i,'non-').gsub('_',' ').titleize,
          row[:characters].keys.join.character_set,
          row[:count].to_s
        ]
      end
      
      def formatted_table
        [fields] + data_table.map {|row| format_row(row) }
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
