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

require 'lib/examination/stat_hash'

class String
  class Examination
    # Abstract base class
    # Subclasses need to define patterns
    class CountTable < String::Examination::StatHash
      class Result < ::Array
        include StatHash::RowFormatting
        
        def initialize(exam, array)
          @exam = exam
          super(0)
          push(*array)
        end

        def format_rows
          self.map{|row| exam.format_row(row) }
        end
      end

      # Designed be overridden in subclasses
      def fields
        [:category, :count]
      end

      # Designed be overridden in subclasses
      def right_justified_columns
        formatted_table = value.formatted
        if formatted_table.size == 0
          []
        else
          [formatted_table.first.size-1]
        end
      end

      def counts
        unfiltered_counts.reject {|row| row[:count] < (minimum||1) }
        .sort_by{|row| -row[:count]}
      end
      alias_method :analysis, :counts
      
      def make_value(x)
        Result.new(self,x)
      end
    end
  end
end
