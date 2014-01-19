#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Check: does data contain tabs?

require 'lib/examination/boolean'

class String
  class Examination
    class Tabbed < Boolean
      def self.description
        "Does data contain tabs?"
      end
      
      def test
        string.tabbed?
      end
    end
  end
end
