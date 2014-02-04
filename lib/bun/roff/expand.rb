#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# This would have been much more difficult without the help of others!
# A million thanks for Treetop: http://treetop.rubyforge.org/index.html
# And for the "how to" notes by Aaron Gough:
#   http://thingsaaronmade.com/blog/a-quick-intro-to-writing-a-parser-using-treetop.html

require 'treetop'
require 'lib/bun/roff/expand_treetop_parser'

class Treetop::Runtime::SyntaxNode
  def roff
    input.roff
  end
end

module Bun
  class Roff
    class RoffInput < String
      attr_accessor :roff
    end

    def expand(line, options={})
      input = RoffInput.new(line+"\n")
      input.roff = self
      tree = parser.parse(input)
      if tree.nil?
        parser.failure_reason =~ /^(Expected .+) at line \d+, (.+) after/m
        expectation = $1
        location = $2
        warn "!Parse error: #{expectation.gsub("\n", '\\n')} at #{location}:\n    #{line}\n    #{' ' * (parser.failure_column - 1)}^"
      end
      tree
    end

    def parser
      @parser ||= RoffInputParser.new
    end
  end
end