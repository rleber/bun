#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Counts words

require 'lib/string_examination/count_table'

class String
  class Examination
    # Abstract base class
    # Subclasses need to define patterns
    class Words < Runs
      attr_accessor :case_insensitive
      
      def self.description
        "Count runs of word characters"
      end
      
      def runs
        s = case_insensitive ? string.downcase : string
        s.split(/\W+/).reject {|run| run=='' }
      end
      
      def calculate_counts
        runs.group_by{|run| run }
            .to_a
            .map{|word, words| {word: word, count: words.size} }
      end
            
      def categories
        counts.map{|word, words| word }
      end
      
      def fields
        [:word, :count]
      end
      
      def format_word(row)
        row[:word].safe
      end
      
      def right_justified_rows
        [1]
      end
    end
  end
end
