#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# This would have been much more difficult without the help of others!
# A million thanks for Treetop: http://treetop.rubyforge.org/index.html
# And for the "how to" notes by Aaron Gough:
#   http://thingsaaronmade.com/blog/a-quick-intro-to-writing-a-parser-using-treetop.html

require 'treetop'
require 'lib/bun/roff/parser'

class Treetop::Runtime::SyntaxNode
  def roff
    input.roff
  end
end

class RoffInputParser < Treetop::Runtime::CompiledParser
  attr_accessor :roff
end

module Bun
  class Roff
    class RoffInput < String
      attr_accessor :roff
    end

    class ParsedLine < Array
      def inspect
        s = super
        self.class.to_s.sub(/^.*::/,'') + s
      end

      def to_a
        Array.new(self)
      end

      def tokens
        self.to_a
      end
    end

    class ParsedText < ParsedLine; end
    class ParsedRequest < ParsedLine; end

    def parse(line, options={})
      input = RoffInput.new(line+"\n")
      input.roff = self
      tree = parser.parse(input)
      if tree.nil?
        parser.failure_reason =~ /^(Expected .+) at line \d+, (.+) after/m
        expectation = $1
        location = $2
        warn "!Parse error: #{expectation.gsub("\n", '\\n')} at #{location}:\n    #{line}\n    #{' ' * (parser.failure_column - 1)}^"
      end
      tokens = tree.parse
      if tokens.size == 0 || tokens.first.type != :request_word
        ParsedText.new(tokens)
      else
        ParsedRequest.new(tokens)
      end
    end

    def parser
      unless @parser
        @parser = RoffInputParser.new
        @parser.roff = self
      end
      @parser
    end
  end
end