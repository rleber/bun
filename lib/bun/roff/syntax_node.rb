#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

module Bun
  class Roff
    module SyntaxNode
      class Base < Treetop::Runtime::SyntaxNode
        def rule
          self.class.to_s.sub(/^.*::/,'').underscore.to_sym
        end

        def create(type, tt)
          Bun::Roff::ParsedNode.create(type, tt)
        end

        def parse
          [ Bun::Roff::ParsedNode.create(rule, self) ]
        end
      end

      class RequestWord < Base; end
      class Other < Base; end
      class QuotedString < Base; end
      class RegisterReference < Base; end
      class Number < Base; end
      class Word < Base; end
      class Parameter < Base; end
      class Escape < Base; end
      class Insertion < Base; end
      class ParenthesizedSentence < Base; end
      class Whitespace < Base; end
      class EndOfLine < Base; end
      class Operator < Base; end
    end
  end
end