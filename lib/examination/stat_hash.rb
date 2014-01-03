#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Abstract base class for creating arrays of statistics
#
# Expected usage:
#
#   class Foo < String::Examination::CountTable
#     def self.description; ... end
#     
#     def unfiltered_counts; ... end
#     def categories; ... end
#     def fields; ... end # Optional
#     def right_justified_columns; ... end # Optional
#   end
#
#   res = "abcde".examine(:foo) # Yields a String::Examination::CountTable::Result,
#                               # which (mostly) behave like an Array
#   res.to_s                    # Formats result

require 'lib/examination/base'

class String
  class Examination
    # Abstract base class
    # Subclasses need to define patterns
    class StatHash < Base
      module RowFormatting
        def exam
          @exam
        end
        
        def right_justified
          @right_justified
        end
        
        def right_justified=(x)
          @right_justified=x
        end
        
        # Designed to be overridden in subclasses
        # MUST return an Array of formatted rows (even if there's just one row)
        def format_rows
          [exam.format_row(self)]
        end
        
        def formatted
          unless @formatted
            @formatted = format_rows
            titles = exam.titles rescue nil
            @formatted.unshift titles if titles
          end
          @formatted
        end
            
        def justified
          tbl = formatted
          tbl.justify_rows(right_justify: exam.right_justified_columns)
        end
      
        def rows
          justified.map{|row| row.join('  ')}
        end
              
        def to_s
          rows.join("\n")
        end
        
        def fields
          exam.fields
        end
        
        def titles
          exam.titles
        end
        
        def title_hash
          fields..zip(exam.titles).inject({}) do |hsh, pair|
            key, value = pair
            hsh[key] = value
            hsh
          end
        end
      end
      
      class Result < ::Hash
        include RowFormatting
        
        def initialize(exam, hash)
          @exam = exam
          super()
          self.merge!(hash)
        end
      end
      
      attr_accessor :minimum

      def categories
        missing_method :categories
      end
      
      # Must be defined subclasses
      def fields
        missing_method :fields
      end
      
      # Designed to be overridden in subclasses
      def titles
        fields.map{|f| f.to_s.gsub('_',' ').titleize }
      end

      # Designed be overridden in subclasses
      def right_justified_columns
      end
      alias_method :right_justified, :right_justified_columns

      # Subclasses may define a set of "format_xxx" methods for each field
    
      def format_row(row)
        fields.map do |f|
          if respond_to?("format_#{f}")
            send("format_#{f}", row)
          else
            row[f].to_s
          end
        end
      end
      alias_method :format, :format_row
            
      def make_value(x)
        Result.new(self,x)
      end
    end
  end
end
