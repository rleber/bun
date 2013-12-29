#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Base classes to define analyses on strings

class String
  class Analysis
    class Base
      attr_accessor :string
      attr_accessor :patterns
    
      def initialize(string, patterns=[/./])
        @string = string
        @patterns = patterns
      end
      
      # Subclasses should define check method
      
      # Subclasses may want to redefine this
      def to_s
        check.to_s
      end
    end
  end
end
