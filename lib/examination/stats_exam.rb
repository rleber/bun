#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Calculate some statistics about the likelihood that this is not a text file

require 'lib/examination/character_class'

class String
  class Examination
    class Stats < String::Examination::StatHash
      
      def self.description
        "Statistics about likelihood this is not a text file"
      end
      
      def analysis
        fields.inject({}) do |hsh, field|
          hsh[field] = String::Examination.examination(string, field)
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
