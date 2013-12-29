#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Classes to define checks on strings

# TODO DRY this out with String::Analysis
class String
  class Check
    class Invalid < ArgumentError; end
    
    class << self
      def create(name)
        class_name = name.titleize
        raise Invalid, "Check class not defined: #{class_name}" unless const_defined?(class_name)
        const_get(class_name).new
      end
    end
  end
end

require 'lib/string'
require 'lib/string_check/base'
require 'lib/string_check/clean'
