#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Check: does data contain apparent roff commands ('.xx ...', etc.)

require 'lib/trait/boolean'

class String
  class Trait
    class Roff < Boolean
      def self.description
        "Does text contain roff commands?"
      end
      
      def test
        string =~ /^\.[a-zA-Z]{,2}(?:\s|$)/
      end
    end
  end
end
