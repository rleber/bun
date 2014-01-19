#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Count occurrences of all characters

require 'lib/examination/character_class'

class String
  class Examination
    class Chars < CharacterClass
      
      PATTERN_HASH = (0...256).inject({}) {|hsh, i| hsh[i] = i.chr; hsh }
      
      def self.description
        "Count every character"
      end

      def fields
        [:character, :count]
      end

      def format_row(row)
        debug row.inspect
        debug row[:characters].keys.join.inspect
        debug row[:characters].keys.join.character_set(single_as_string: true).inspect
        [
          row[:characters].keys.join.character_set(single_as_string: true),
          row[:count].to_s
        ]
      end
    end
  end
end
