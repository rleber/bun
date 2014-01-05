#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Abstract base class for numeric examinations
#
# Usage:
#   class Foo < String::Examination::Numeric
#     def self.description; ... end
#     def analysis; ... end
#     def format(x); ... end
#   end
#
#   analysis = "abcde".examine(:foo)
#   numeric_result = analysis.value
#   formatted_result = analysis.to_s 

class String
  class Examination
    class Numeric < Base
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
        
        # Behave like a Float
        def method_missing(meth, *args, &blk)
          value.send(meth, *args, &blk)
        end
      end
      
      # Default; may be overridden in subclasses
      def self.justification
        :right
      end

      def make_value(x)
        Result.new(self, x)
      end
      
      def format(x)
        x.to_s
      end
      
      def to_i
        value.to_i
      end
      
      def to_f
        value.to_f
      end
      
      def to_s
        format(value)
      end
    end
  end
end
