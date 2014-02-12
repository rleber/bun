#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

module Bun
  class Roff
    class ParsedNode
      class << self
        def create_from_syntax_node(type, syntax_node)
          create(type, text: syntax_node.text_value, interval: syntax_node.interval, syntax_node: syntax_node)
        end

        def create(type, options={})
          class_name = type.to_s.camelcase
          klass = const_defined?(class_name) ? const_get(class_name) : self
          klass.new(type, options)
        end
      end

      attr_reader :syntax_node, :type, :text, :interval, :value

      def initialize(type, options={})
        @type = type
        @syntax_node = options[:syntax_node]
        @text = options[:text]
        @value = options[:value] || calculate_value
        @interval = options[:interval]
      end

      def inspect
        "#{type}(#{text.inspect})"
      end

      def calculate_value
        self.text
      end

      def output_text
        value
      end

      def compressed
        self
      end

      class RequestWord < ParsedNode
        def calculate_value
          text[1..-1]
        end
      end

      class QuotedString < ParsedNode
        def calculate_value
          text[1..-2].gsub('""','\"')
        end
      end

      class RegisterReference < ParsedNode
        def calculate_value
          text[1..-2]
        end

        def output_text
          text
        end
      end    

      class Number < ParsedNode
        def calculate_value
          text.to_i
        end

        def output_text
          text
        end
      end    

      class Parameter < ParsedNode
        def calculate_value
          text[1..-1].to_i
        end
      end    

      class Escape < ParsedNode
        def calculate_value
          text[1,1]
        end
      end    

      class Nested < ParsedNode
        attr_accessor :nested_sentence
        def initialize(type, options={})
          self.nested_sentence = if options[:nested_sentence]
            options[:nested_sentence]
          elsif options[:syntax_node]
            options[:syntax_node].nested_sentence.parse
          else
            raise ArgumentError, "Must specify :nested_sentence or :syntax_node option"
          end
          super
        end

        def calculate_value
          nested_sentence
        end

        def inspect
          "#{type}(#{self.value ? self.value.map{|v| v.inspect}.join(',') : 'nil'})"
        end
      end    

      class Insertion < Nested; end
      class ParenthesizedSentence < Nested; end

      class Whitespace < ParsedNode
        def calculate_value
          ' '
        end

        def compressed
          nil
        end
      end    

      class EndOfLine < Whitespace
        def calculate_value
          ' '
        end
      end    
    end
  end
end