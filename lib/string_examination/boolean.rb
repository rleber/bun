#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Abstract base class for boolean checks

require 'lib/string_examination/base'

class String
  class Examination
    class Boolean < Base
      
      def labels
        missing_method :labels
      end
      
      def true?
        missing_method :true
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
    end
  end
end
