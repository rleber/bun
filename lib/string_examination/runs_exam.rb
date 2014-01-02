#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Count runs of word characters

require 'lib/string_examination/count_table'

class String
  class Examination
    # Abstract base class
    # Subclasses need to define patterns
    class Runs < CountTable

      def self.description
        "Count runs of word characters"
      end
      
      def runs
        string.split(/\W+/).reject {|run| run=='' }
      end
      
      def calculate_counts
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
      
      def right_justified_rows
        [0,1]
      end
    end
  end
end
