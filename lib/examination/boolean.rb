#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Abstract base class for boolean checks

require 'lib/examination/base'

class String
  class Examination
    class Boolean < Base

      # TODO Refactor this; DRY it up with Numeric, e.g.
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
        
        # Behave like a Float
        def method_missing(meth, *args, &blk)
          value.send(meth, *args, &blk)
        end
      end
      
      def labels
        missing_method :labels
      end
      
      def true?
        missing_method :true?
      end
      
      def analysis
        if true?
          res = labels[0]
          @code = 0
        else
          res = labels[1]
          @code = 1
        end
        res
      end

      # Default; may be overridden in subclasses
      # TODO Is this used anywhere?
      def self.justification
        :left
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

      def right_justified_columns
        value.right_justified_columns
      end

      def titles
        nil
      end
    end
  end
end
