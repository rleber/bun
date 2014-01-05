#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Calculate some statistics about the likelihood that this is not a text file

require 'lib/examination/character_class'

class String
  class Examination
    class Stats < String::Examination::StatHash
      
      
      
      PRINTABLE_CHARACTERS = 'a-zA-Z0-9\.,(){}\[\]:;\-\'"! \\#$%&*+/<=>?@^_`|~\t\n\b\v\f\a'
      PATTERN_HASH = {
        printable: /[#{PRINTABLE_CHARACTERS}]/,
        non_printable: /[^#{PRINTABLE_CHARACTERS}]/
      }
      
      def self.description
        "Statistics about likelihood this is not a text file"
      end
      
      def analysis
        fields.inject({}) do |hsh, field|
          hsh[field] = String::Examination.examination(string, field)
          hsh
        end
      end
      
      def format_run_size(row)
        "%0.2f" % row[:run_size]
      end
      
      def fields
        [:run_size, :legibility, :english, :overstruck, :roff]
      end

      # def right_justified_columns
      #   [0,1]
      # end
      
      # def make_value(x)
      #   Result.new(self,x)
      # end
    end
  end
end
