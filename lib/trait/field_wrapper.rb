#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Calculate proportion of readable vs. non-readable characters

require 'lib/trait/wrapper'

class String
  class Trait
    class FieldWrapper < String::Trait::Wrapper
      def self.description
        "Encapsulize a file field value"
      end

      attr_reader :field_name

      def initialize(field_name, value, options={})
        super(value, options)
        @field_name = field_name
      end

      def titles
        [@field_name.to_s.gsub('_',' ').titleize]
      end
    end
  end
end
