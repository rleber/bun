#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Check: does data contain overstrikes (i.e. backspaces)?

require 'lib/examination/boolean'

class String
  class Examination
    class Overstruck < Boolean
      def self.description
        "Does data contain backspaces?"
      end
      
      def labels
        [:overstruck, :not_overstruck]
      end
      
      def true?
        string.overstruck?
      end
    end
  end
end
