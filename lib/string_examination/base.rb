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
      
      # Subclasses should define check method
      def analysis
        missing_method :analysis
      end
      alias_method :value, :analysis
      
      def to_s
        analysis.to_s
      end
    end
  end
end
