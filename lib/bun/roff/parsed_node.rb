#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

module Bun
  class Roff
    class ParsedNode
      class << self
        def create(type, tt)
          class_name = type.to_s.camelcase
          klass = const_defined?(class_name) ? const_get(class_name) : self
          klass.new(type, tt)
        end
      end

      attr_reader :tt, :type, :text, :interval

      def initialize(type, tt)
        @type = type
        @tt = tt
        @text = tt.text_value
        @interval = tt.interval
      end

      def inspect
        "#{type}(#{text.inspect})"
      end

      def value
        self.text
      end

      def compressed
        value
      end

      class RequestWord < ParsedNode
        def value
          text[1..-1]
        end
      end

      class QuotedString < ParsedNode
        def value
          text[1..-2].gsub('""','\"')
        end
      end

      class RegisterReference < ParsedNode
        def value
          text[1..-1]
        end
      end    

      class Number < ParsedNode
        def value
          text.to_i
        end
      end    

      class Parameter < ParsedNode
        def value
          text[1..-1].to_i
        end
      end    

      class Escape < ParsedNode
        def value
          text[1,1]
        end
      end    

      class Nested < ParsedNode
        def value
          tt.nested_sentence.parse
        end

        def inspect
          "#{type}(#{value.map{|v| v.inspect}.join(',')})"
        end
      end    

      class Insertion < Nested; end
      class ParenthesizedSentence < Nested; end

      class Whitespace < ParsedNode
        def value
          ' '
        end

        def compressed
          nil
        end
      end    

      class EndOfLine < Whitespace
        # TODO Improve this to look for end of sentence on value?
      end    
    end
  end
end