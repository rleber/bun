#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Check: does data contain apparent roff commands ('.xx ...', etc.)

require 'lib/string_examination/boolean'

class String
  class Examination
    class Roff < Boolean
      def self.description
        "Does text contain roff commands?"
      end
      
      def labels
        [:roff, :no_roff]
      end
      
      def true?
        string =~ /^\.[a-zA-Z]{,2}(?:\s|$)/
      end
    end
  end
end