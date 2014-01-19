#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Abstract base class for boolean checks

require 'lib/examination/base'

class String
  class Examination
    class Boolean < Base
      def test
        missing_method :test
      end
      
      def analysis
        res = test
        @code = res ? 0 : 1
        res = labels(@code) if self.respond_to?(:labels)
        res
      end
    end
  end
end
