#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# List non-english words

require 'lib/examination/numeric'

class String
  class Examination
    class NonEnglishWords < CountTable
      
      # TODO Dry this out with English
      # TODO Supply in/out parameter for english vs non-english words
      # TODO Put this in config
      LIBRARY_FILE = '/usr/share/dict/words'
      
      def self.description
        "List non-english words"
      end
      
      def library
        @library ||= ::File.read(LIBRARY_FILE)
                           .chomp
                           .split("\n")
                           .inject({}) {|hsh, word| w = word.strip.downcase; hsh[w] = true; hsh }
      end
      
      def is_english(word)
        library[word.strip.downcase]
      end
      
      def fields
        [:word, :count]
      end
      
      def analysis
        word_counts = String::Examination.examine(string, :words)
        word_counts.reject{|row| is_english(row[:word])}
      end
    end
  end
end
