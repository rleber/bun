#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Check: does data contain overstrikes (i.e. backspaces)?

require 'lib/trait/boolean'

class String
  class Trait
    class Overstruck < Boolean
      def self.description
        "Does data contain backspaces?"
      end

      def test
        string.overstruck?
      end
    end
  end
end
