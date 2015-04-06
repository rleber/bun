#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Abstract base class for creating arrays of statistics
#
# Expected usage:
#
#   class Foo < String::Trait::CountTable
#     def self.description; ... end
#     
#     def unfiltered_counts; ... end
#     def categories; ... end
#     def fields; ... end # Optional
#     def right_justified_columns; ... end # Optional
#   end
#
#   res = "abcde".examine(:foo) # Yields a String::Trait::CountTable::Result,
#                               # which (mostly) behave like an Array
#   res.to_s                    # Formats result

require 'lib/trait/base'

class String
  class Trait
    # Abstract base class
    # Subclasses need to define patterns
    class StatHash < Base
      module RowFormatting
        def trait
          @trait
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
          [trait.format_row(self)]
        end
        
        def justified
          tbl = to_titled_matrix
          tbl.justify_rows(right_justify: trait.right_justified_columns)
        end
      
        def rows
          justified.map{|row| row.join('  ')}
        end
              
        def to_s
          rows.join("\n")
        end

        def to_matrix
          @matrix ||= format_rows
        end

        def titles
          trait.titles rescue nil
        end

        def to_titled_matrix
          # debug caller
          [titles ? [titles] : []] + to_matrix
        end

        def fields
          trait.fields
        end
        
        def titles
          trait.titles
        end
        
        def title_hash
          fields..zip(trait.titles).inject({}) do |hsh, pair|
            key, value = pair
            hsh[key] = value
            hsh
          end
        end
      end
      
      class Result < ::Hash
        include RowFormatting
        
        def initialize(trait, hash)
          @trait = trait
          super()
          self.merge!(hash)
        end

        def right_justified_columns
          trait.right_justified_columns
        end
      end
      
      attr_accessor :minimum
      option "minimum", :desc=>"Only include occurrences with at least this minimum count"

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
        res = fields.map.with_index do |field, i|
          klass = String::Trait.trait_class(field) rescue nil
          justification = klass && klass.justification rescue :left
          [justification, i]
        end
        res = res.select {|justification, index| justification == :right}
                 .map{|justification, index| index}
        res
      end
      alias_method :right_justified, :right_justified_columns

      # Subclasses may define a set of "format_xxx" methods for each field
      def format_field(f, row)
        if respond_to?("format_#{f}")
          send("format_#{f}", row)
        else
          row[f].to_s
        end
      end

      def format_row(row)
        fields.map {|f| format_field(f,row) }
      end
      alias_method :fmt, :format_row

      def make_value(x)
        Result.new(self,x)
      end
    end
  end
end
