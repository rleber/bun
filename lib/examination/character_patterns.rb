#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Base classes to define analyses on strings (e.g. counting kinds of characters)

class String
  class Examination
    module CharacterPatterns
      def patterns
        @patterns
      end
      
      def patterns=(p)
        @patterns=p
      end
  
      # This allows subclasses to do things like remove zero values
      def unfiltered_counts
        encoded = string.force_encoding('ascii-8bit')
        cts = []
        [patterns].flatten.each.with_index do |pat, i|
          cts[i] = {index:i, characters: {}, count: 0}
          encoded.scan(pat) do |ch|
            cts[i][:count] += 1
            cts[i][:characters][ch] ||= 0
            cts[i][:characters][ch] += 1
          end
        end
        cts
      end
      
      def counts
        unfiltered_counts
      end
  
      def count_hash
        cts = counts
        cts.inject({}) do |hsh, entry|
          hsh[entry[:characters].keys.sort.join] = entry[:count]
          hsh
        end
      end
    end
  end
end
