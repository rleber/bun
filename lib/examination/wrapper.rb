#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Calculate proportion of readable vs. non-readable characters

require 'lib/examination/base'

class String
  class Examination
    class Wrapper < String::Examination::Base
      def self.description
        "Encapsulize a scalar value"
      end

      class ValueWrapper
        attr_accessor :value
        def initialize(value)
          @value = value
        end

        def to_matrix
          [[value]]
        end

        def to_s
          value.to_s
        end

        def code
          value.code
        end

        def method_missing(method, *args, &blk)
          if value.respond_to?(method)
            value.send(method, *args, &blk)
          else
            raise NoMethodError, "#{self.class} value #{value} does not have a #{method} method"
          end
        end
      end

      attr_reader :value
      attr_accessor :right_justified_columns

      def initialize(value, string='', options={})
        super(string, options)
        @value = value
        @right_justified_columns = value.is_a?(::Numeric) ? [0] : []
      end

      def value
        ValueWrapper.new(@value)
      end

      def titles
        nil
      end
      
      def analysis
        @value
      end
      
      def format(x)
        x.to_s
      end

      def code
        value.code
      end

      def method_missing(method, *args, &blk)
        value.send(method, *args, &blk)
      end
    end
  end
end
