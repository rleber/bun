#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Check if string is all readable characters

class String
  class Check
    class Clean < Boolean
      
      def labels
        [:clean, :dirty]
      end
      
      def okay?
        string.clean?
      end
    end
  end
end
