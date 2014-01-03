#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Base class to define analyses or tests on strings

class String
  class Examination
    class Base
      attr_accessor :string
      attr_reader :code
      
      # Should be overridden in subclasses
      def self.description
      end
      
      def description
        self.class.description
      end
      
      def missing_method(meth)
        stop "!#{self.class} does not define #{meth} method"
      end
    
      def initialize(string='')
        @string = string
        @code = 0
      end
      
      # Subclasses should define analysis method
      def analysis
        missing_method :analysis
      end
      
      # This allows subclass hooks, e.g.
      #    def set_value(x)
      #      ResultClass.new(x)
      #    end
      def set_value(x)
        x
      end
      
      def value
        @value ||= set_value(analysis)
      end
      
      def reset
        @value = nil
      end
      
      def recalculate
        reset
        value
      end
      
      def to_s
        value.to_s
      end
    end
  end
end
