#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Base classes to define checks on strings

class String
  class Check
    class Overstruck < Boolean
      
      def labels
        [:overstruck, :not_overstruck]
      end
      
      def okay?
        string.overstruck?
      end
    end
  end
end
