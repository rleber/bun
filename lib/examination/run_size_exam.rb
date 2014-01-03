#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Calculate average size of runs of readable characters

require 'lib/examination/numeric'

class String
  class Examination
    class RunSize < String::Examination::Numeric
      
      def self.description
        "Calculate average size of runs of readable characters"
      end
      
      def analysis
        counts = String::Examination.examine(string, :runs)
        total_runs = 0
        total_run_size = 0
        counts.each do |row|
          total_runs += row[:count]
          total_run_size += (row[:count]*row[:length])
        end
        total_run_size*1.0 / total_runs
      end
      
      def format(x)
        '%0.2f' % x
      end
    end
  end
end
