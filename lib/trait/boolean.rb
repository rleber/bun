#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Abstract base class for boolean checks

require 'lib/trait/base'

class String
  class Trait
    class Boolean < Base
      class Result < String::Trait::Base::Result 
        def !
          self.not
        end

        def not
          res = self.dup
          res.value = !self.value
          res
        end
      end

      class << self
        def result_class
          Result
        end
      end

      def !
        self.value.not
      end

      def test
        missing_method :test
      end
      
      def analysis
        res = test
        @code = res ? 0 : 1
        res
      end

      def fmt(x)
        x = x.value if x.is_a?(String::Trait::Base::Result)
        if self.respond_to?(:labels)
          labels(x ? 0: 1)
        else
          x ? 'true' : 'false'
        end
      end
    end
  end
end
