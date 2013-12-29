#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Classes to define checks on strings

# TODO DRY this out with String::Analysis
class String
  class Check
    class Invalid < ArgumentError; end
    
    class << self
      def create(check, string='')
        class_name = check.to_s.titleize
        raise Invalid, "Check class not defined: #{class_name}" unless const_defined?(class_name)
        const_get(class_name).new(string)
      end
      
      def check(string, check)
        create(check, string).check
      end
    end
  end
end

require 'lib/string'
require 'lib/string_check/base'
require 'lib/string_check/clean'
require 'lib/string_check/readability'
