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
        res
      end

      def format(x)
        x = x.value if x.is_a?(String::Examination::Base::Result)
        if self.respond_to?(:labels)
          labels(x ? 0: 1)
        else
          x ? 'true' : 'false'
        end
      end
    end
  end
end
