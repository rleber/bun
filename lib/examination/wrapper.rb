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

      def self.wrap(value, options={})
        case value
        when String::Examination::Base, String::Examination::FieldWrapper, String::Examination::Wrapper
          value
        else
          self.new(value, options)
        end
      end

      class ValueWrapper
        attr_accessor :exam
        attr_accessor :value
        attr_accessor :right_justified_columns

        def initialize(exam, value)
          @exam = exam
          @value = value
          @right_justified_columns = value.is_a?(::Numeric) ? [0] : []
        end

        def to_matrix
          [[to_s]]
        end

        def to_s
          case value
          when NilClass, Symbol
            value.inspect
          else
            value.to_s
          end
        end

        def code
          value.code rescue nil
        end

        def titles
          exam.titles
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
      attr_accessor :right_justified_columns, :titles

      def self.result_class
        ValueWrapper
      end

      # TODO Some of this is redundant
      def initialize(value, options={})
        super(options)
        @value = wrap(value)
        @right_justified_columns = value.is_a?(::Numeric) ? [0] : []
        @titles = options[:titles]
      end
      
      def analysis
        @value
      end

      def code
        value.code
      end

      def wrap(value)
        self.class.result_class.new(self, value)
      end

      def method_missing(method, *args, &blk)
        value.send(method, *args, &blk)
      end
    end
  end
end
