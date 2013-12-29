#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Classes to define analysis of english vs. non-english characters

require 'lib/string'

class String
  class Analysis
    class Chars < CharacterClass
      
      PATTERN_HASH = (0...256).inject({}) {|hsh, i| hsh[i] = i.chr; hsh }
      
      def description
        "Count every character"
      end

      def format_row(row)
        [
          row[:characters].keys.join.character_set,
          row[:count].to_s
        ]
      end
    end
  end
end
