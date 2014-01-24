#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Check if string is all readable characters

require 'lib/trait/boolean'

class String
  class Trait
    class Clean < Boolean

      def self.description
        "Test if data contains unreadable characters"
      end
      
      def test
        string.clean?
      end
    end
  end
end
