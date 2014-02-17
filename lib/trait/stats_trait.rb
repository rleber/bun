#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Calculate some statistics about the likelihood that this is not a text file

require 'lib/trait/character_class'

class String
  class Trait
    class Stats < String::Trait::StatHash
      
      def self.description
        "Statistics about likelihood this is not a text file"
      end
      
      def analysis
        fields.inject({}) do |hsh, field|
          hsh[field] = String::Trait.trait(string, field)
          hsh
        end
      end
      
      # TODO Is this necessary?
      def format_run_size(row)
        "%0.2f" % row[:run_size]
      end
      
      def fields
        [:run_size, :legibility, :english, :overstruck, :roff]
      end
    end
  end
end
