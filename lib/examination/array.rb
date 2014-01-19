#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Abstract base class for array examinations
#
# Usage:
#   class Foo < String::Examination::Array
#     def self.description; ... end
#     def analysis; ... end
#     def format(x); ... end
#   end
#
#   analysis = "abcde".examine(:foo)
#   array_result = analysis.value
#   formatted_result = analysis.to_s 

# TODO I don't think this class is necessary at all

require 'lib/examination/base'

class String
  class Examination
    class Array < Base
      class Result
        attr_accessor :exam
        attr_accessor :value
        
        def initialize(exam,value)
          @exam = exam
          @value = value
        end

        def to_s
          exam.format(value)
        end

        def to_matrix
          [[exam.format(value)]]
        end

        # TODO Some of this could be dried up with other Result classes with a Mixin
        def titles
          exam.titles rescue nil 
        end

        def to_titled_matrix
          [titles ? [titles] : []] + to_matrix
        end

        def right_justified_columns
          []
        end
        
        # Behave like an Array
        def method_missing(meth, *args, &blk)
          value.send(meth, *args, &blk)
        end
      end
      
      # Default; may be overridden in subclasses
      def self.justification
        :left
      end

      def make_value(x)
        Result.new(self, x)
      end
      
      def format(x)
        x.to_s
      end
      
      def to_s
        format(value)
      end
    end
  end
end
