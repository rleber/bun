#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Abstract base class for counting classes of characters
#
# Expected usage:
#
#   class Foo < String::Trait::CountTable
#     def self.description; ... end
#     def unfiltered_counts; ... end
#     def categories; ... end
#     def fields; ... end # Optional
#     def right_justified_columns; ... end # Optional
#   end
#
#   res = "abcde".examine(:foo) # Yields a String::Trait::CountTable::Result,
#                               # which (mostly) behave like an Array
#   res.to_s                    # Formats result

require 'lib/trait/stat_hash'

class String
  class Trait
    # Abstract base class
    # Subclasses need to define patterns
    class FieldValues < String::Trait::StatHash
      class Result < ::Array
        include StatHash::RowFormatting
        
        def initialize(trait, array)
          @trait = trait
          super(0)
          push(*array)
        end

        def format_rows
          self.map{|row| trait.format_row(row) }
        end

        def right_justified_columns
          trait.right_justified_columns
        end

        def code
          nil
        end
      end

      def self.description
        "Count different control characters"
      end

      # Designed be overridden in subclasses
      def fields
        [:field, :value]
      end

      # Designed be overridden in subclasses
      def right_justified_columns
        []
      end

      def field_names
        (file.descriptor.fields.map{|f| f.to_sym} + Bun::File::Descriptor::Base.file_fields.keys).uniq
      end

      def analysis
        field_names.sort.map do |name|
          {field: name, value: file.descriptor[name]}
        end
      end

      def format_row(row)
        [
          row[:field].inspect,
          row[:value].inspect
        ]
      end

      def make_value(x)
        Result.new(self,x)
      end
    end
  end
end
