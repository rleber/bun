#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Base classes to define checks on strings

class String
  class Check
    class Clean < Base
      
      def check
        if string.clean?
          res = :clean
          @code = 0
        else
          res = :dirty
          @code = 1
        end
        res
      end
    end
  end
end
