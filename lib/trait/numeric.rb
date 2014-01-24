#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Abstract base class for numeric traits
#
# Usage:
#   class Foo < String::Trait::Numeric
#     def self.description; ... end
#     def analysis; ... end
#     def format(x); ... end
#   end
#
#   analysis = "abcde".examine(:foo)
#   numeric_result = analysis.value
#   formatted_result = analysis.to_s 

class String
  class Trait
    class Numeric < Base
      class Result < String::Trait::Base::Result
        def right_justified_columns
          [0]
        end
      end

      def self.result_class
        Result
      end
      
      # Default; may be overridden in subclasses
      def self.justification
        :right
      end
    end
  end
end
