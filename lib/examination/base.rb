#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Base class to define analyses or tests on strings

class String
  class Examination
    class Base
      attr_accessor :string
      attr_reader :code
      attr_accessor :options
      
      # Should be overridden in subclasses
      def self.description
      end
      
      # Default; may be overridden in subclasses
      def self.justification
        :left
      end
      
      def description
        self.class.description
      end
      
      def missing_method(meth)
        stop "!#{self.class} does not define #{meth} method"
      end
    
      def initialize(string='', options={})
        @string = string
        @code = 0
        @options = options
      end
      
      # Subclasses should define analysis method
      def analysis
        missing_method :analysis
      end
      
      # This allows subclass hooks, e.g.
      #    def make_value(x)
      #      ResultClass.new(x)
      #    end
      def make_value(x)
        x
      end
      
      def value
        self.value = make_value(analysis) unless @value
        @value
      end
      
      def value=(x)
        @value=x
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
      
      def inspect
        value.inspect
      end
    end
  end
end
