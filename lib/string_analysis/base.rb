#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Base classes to define checks on strings

class String
  class Analysis
    class Base
      attr_accessor :string
      attr_accessor :patterns
    
      def initialize(string, patterns=[/./])
        @string = string
        @patterns = patterns
      end
  
      def counts
        encoded = @string.force_encoding('ascii-8bit')
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
  
      def character_class_counts
        cts = counts
        cts.inject({}) do |hsh, entry|
          hsh[entry[:characters].keys.sort.join] = entry[:count]
          hsh
        end
      end
    end
  end
end
