#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Abstract base class for boolean checks

require 'lib/examination/base'

class String
  class Examination
    class Boolean < Base
      
      def labels
        basename = class_basename.downcase
        [basename, "not_#{basename}"].map{|label| label.to_sym }
      end
      
      def true?
        missing_method :true?
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
