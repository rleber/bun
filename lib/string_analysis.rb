#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Classes to define analyses on strings

class String
  class Analysis
    class Invalid < ArgumentError; end
    
    class << self
      def create(name)
        class_name = name.titleize
        raise Invalid, "Analysis class not defined: #{class_name}" unless const_defined?(class_name)
        const_get(class_name).new
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
