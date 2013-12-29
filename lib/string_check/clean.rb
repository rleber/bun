#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Base classes to define checks on strings

class String
  class Check
    class Clean < Base
      
      def check
        string.clean? ? :clean : :dirty
      end
    end
  end
end
