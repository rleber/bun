#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Counts words

require 'lib/trait/count_table'

class String
  class Trait
    # Abstract base class
    # Subclasses need to define patterns
    class Words < Runs
      attr_accessor :case_insensitive
      
      option "case_insensitive", :desc=>"Ignore upper and lower case"

      def self.description
        "Count words"
      end
            
      def categories
        counts.map{|word, words| word }
      end

      def unfiltered_counts
        runs.group_by{|run| run}
            .to_a
            .map{|word, words| {word: word, count: words.size} }
      end
      
      def fields
        [:word, :count]
      end
      
      def format_word(row)
        row[:word].safe
      end
      
      def right_justified_columns
        [1]
      end
    end
  end
end
