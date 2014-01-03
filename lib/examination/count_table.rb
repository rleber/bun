#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Abstract base class for counting classes of characters
#
# Expected usage:
#
#   class Foo < String::Examination::CountTable
#     def self.description; ... end
#     def unfiltered_counts; ... end
#     def categories; ... end
#     def fields; ... end # Optional
#     def right_justified_columns; ... end # Optional
#   end
#
#   res = "abcde".examine(:foo) # Yields a String::Examination::CountTable::Result,
#                               # which (mostly) behave like an Array
#   res.to_s                    # Formats result

require 'lib/examination/analysis_base'

class String
  class Examination
    # Abstract base class
    # Subclasses need to define patterns
    class CountTable < AnalysisBase
      
      class Result < Array
        attr_accessor :exam
        attr_accessor :right_justified_columns
        
        def initialize(exam, array)
          @exam = exam
          super(array)
        end
        
        def formatted
          unless @formatted
            @formatted ||= self.map {|row| exam.format_row(row) }
            titles = exam.titles rescue nil
            @formatted.unshift titles if titles
          end
          @formatted
        end
            
        def justified
          tbl = formatted
          tbl.justify_rows(right_justify: right_justified_columns)
        end
      
        def rows
          justified.map{|row| row.join('  ')}
        end
      
        def to_s
          rows.join("\n")
        end
        
        def titles
          exam.titles
        end
      end
      
      attr_accessor :minimum

      def categories
        missing_method :categories
      end
      
      # Designed be overridden in subclasses
      def fields
        [:category, :count]
      end
      
      # Designed to be overridden in subclasses
      def titles
        fields.map{|f| f.to_s.titleize }
      end

      # Designed be overridden in subclasses
      def right_justified_columns
        if formatted_table.size == 0
          []
        else
          [formatted_table.first.size-1]
        end
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
      
      def counts
        unfiltered_counts.reject {|row| row[:count] < (minimum||1) }
        .sort_by{|row| -row[:count]}
      end
      alias_method :analysis, :counts
      
      def set_value(x)
        super(Result.new(self,x))
      end
    end
  end
end
