#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Count runs of word characters

require 'lib/examination/count_table'

class String
  class Examination
    # Abstract base class
    # Subclasses need to define patterns
    class Runs < CountTable
      attr_accessor :case_insensitive

      def self.description
        "Count runs of word characters"
      end
      
      def runs
        s = case_insensitive ? string.downcase : string
        s.split(/\W+/).reject {|run| run=='' }
      end
      
      def unfiltered_counts
        runs.group_by{|run| run.size}
            .to_a
            .map{|len, words| {length: len, count: words.size} }
      end
            
      def categories
        counts.map{|len, words| len }
      end
      
      def fields
        [:length, :count]
      end
      
      def right_justified_columns
        [0,1]
      end
    end
  end
end
