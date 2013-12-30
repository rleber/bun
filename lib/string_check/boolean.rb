#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Abstract base class for boolean checks

class String
  class Check
    class Boolean < Base
      
      # Subclasses should define labels, boolean?
      
      def check
        if okay?
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
