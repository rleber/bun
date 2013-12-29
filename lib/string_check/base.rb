#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Base classes to define analyses on strings

class String
  class Check
    class Base
      attr_accessor :string
    
      def initialize(string='')
        @string = string
      end
      
      # Subclasses should define check method
      
      # Subclasses may want to redefine this
      def to_s
        check.to_s
      end
    end
  end
end
