#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Base classes to define checks on strings

class String
  class Check
    class Tabbed < Boolean
      
      def labels
        [:tabs, :no_tabs]
      end
      
      def okay?
        string.tabbed?
      end
    end
  end
end
