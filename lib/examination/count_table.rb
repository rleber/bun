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

require 'lib/examination/array'

class String
  class Examination
    # Abstract base class
    # Subclasses need to define patterns
    class CountTable < String::Examination::Array
      class Result < String::Examination::CountTable::Result
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
      
      def make_value(x)
        Result.new(self,x)
      end
    end
  end
end
