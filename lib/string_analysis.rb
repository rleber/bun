#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Classes to define analyses on strings

class String
  class Analysis
    class Invalid < ArgumentError; end
    
    class << self
      def create(analysis, string="")
        class_name = analysis.to_s.titleize
        raise Invalid, "Analysis class not defined: #{class_name}" unless const_defined?(class_name)
        const_get(class_name).new(string)
      end
      
      def analyze(string, analysis)
        create(analysis, string).counts
      end
    end
  end
end

require 'lib/string'
require 'lib/string_analysis/base'
require 'lib/string_analysis/character_class'
require 'lib/string_analysis/characters'
require 'lib/string_analysis/printable'
require 'lib/string_analysis/classes'
require 'lib/string_analysis/control_characters'
