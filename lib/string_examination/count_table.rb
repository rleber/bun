#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Abstract base class for counting classes of characters

require 'lib/string_examination/analysis_base'

class String
  class Examination
    # Abstract base class
    # Subclasses need to define patterns
    class CountTable < AnalysisBase
      attr_accessor :minimum

      def categories
        raise "class #{self.class} does not define a categories method"
      end
      
      # Designed be overridden in subclasses
      def fields
        [:category, :count]
      end

      # Designed be overridden in subclasses
      def right_justified_rows
        if formatted_table.size == 0
          []
        else
          [formatted_table.first.size-1]
        end
      end
      
      def titles
        fields.map{|f| f.to_s.titleize }
      end
      
      def reset
        @counts = nil
        @formatted_table = nil
      end
      
      def counts
        @counts ||= calculate_counts
      end
      
      def analysis
        counts.reject {|row| row[:count] < (minimum||1) }
        .sort_by{|row| -row[:count]}
      end
      
      # Subclasses may define a set of "format_xxx" methods for each field
      
      def format_row(row)
        fields.map do |f|
          if respond_to?("format_#{f}")
            send("format_#{f}", row)
          else
            row[f].inspect
          end
        end
      end
      
      def formatted_table
        @formatted_table ||= ([titles] + analysis.map {|row| format_row(row) })
      end
            
      def justified
        tbl = formatted_table
        tbl.justify_rows(right_justify: right_justified_rows)
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
