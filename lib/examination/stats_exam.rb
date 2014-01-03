#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Calculate some statistics about the likelihood that this is an executable file

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
        "Statistics about likelihood this is executable"
      end

      # class Result < String::Examination::CountTable::Result
      #   def format_rows
      #     self.map{|row| exam.format_row(row) }
      #   end
      # end
      
      def analysis
        {
          run_size: String::Examination.examination(string, :run_size), 
          legibility: String::Examination.examination(string, :legibility)
        }
      end
      
      def format_run_size(row)
        "%0.2f" % row[:run_size]
      end
      
      def format_legibility(row)
        row[:legibility].to_s
      end
      
      def fields
        [:run_size, :legibility]
      end

      def right_justified_columns
        [0,1]
      end
      
      # def make_value(x)
      #   Result.new(self,x)
      # end
    end
  end
end
