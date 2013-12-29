#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Base classes to define analyses on strings

class String
  class Analysis
    class Base
      attr_accessor :string
      attr_accessor :patterns
    
      def initialize(string, patterns=[/./])
        @string = string
        @patterns = patterns
      end
  
      def pattern_counts
        encoded = @string.force_encoding('ascii-8bit')
        counts = []
        [patterns].flatten.each.with_index do |pat, i|
          encoded.scan(pat) do |ch|
            counts[i] ||= {index:i, characters: {}, count: 0}
            counts[i][:count] += 1
            counts[i][:characters][ch] ||= 0
            counts[i][:characters][ch] += 1
          end
        end
        counts
      end
  
      def character_counts
        counts = pattern_counts
        counts.inject({}) do |hsh, entry|
          hsh[entry[:characters].keys.sort.join] = entry[:count]
          hsh
        end
      end
    end
  end
end
