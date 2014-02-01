#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Calculate average size of runs of readable characters

require 'lib/trait/numeric'

class String
  class Trait
    class RunSize < String::Trait::Numeric
      
      def self.description
        "Calculate average size of runs of readable characters"
      end
      
      def analysis
        counts = String::Trait.examine(string, :runs)
        total_runs = 0
        total_run_size = 0
        counts.each do |row|
          total_runs += row[:count]
          total_run_size += (row[:count]*row[:length])
        end
        total_run_size*1.0 / total_runs
      end
      
      def fmt(x)
        '%0.2f' % x
      end
    end
  end
end
