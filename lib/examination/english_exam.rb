#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Calculate proportion of english words

require 'lib/examination/numeric'

class String
  class Examination
    class English < String::Examination::Numeric
      
      # TODO Handle root words (e.g. having, have) more intelligently
      # TODO Put this in config
      LIBRARY_FILE = '/usr/share/dict/words'
      
      def self.description
        "Calculate proportion of english words"
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
      
      def analysis
        word_counts = String::Examination.examine(string, :words)
        total_count = word_counts.map{|row| row[:count]}.sum
        english_count = word_counts.select{|row| is_english(row[:word])} \
                         .map{|row| row[:count]}.sum
        english_count*1.0 / total_count
      end
      
      def format(x)
        '%0.2f%' % (x*100.0)
      end
    end
  end
end
