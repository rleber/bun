#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Classes to define analysis of english vs. non-english characters

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
      
      def data_table
        tbl = character_counts.to_a
        tbl += [['',0]]*(categories.size)
        res = []
        categories.size.times do |i|
          res << [categories[i]] + tbl[i]
        end
        res.sort_by{|row| -row[-1]}
      end
      
      def formatted_table
        [fields] + data_table.map do |row|
          [
            row[0].to_s.gsub(/non_/i,'non-').gsub('_',' '),
            row[1].character_set,
            row[2].to_s
          ]
        end
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
