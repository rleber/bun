#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

require 'lib/string'

module Bun
  class Roff
    module SyntaxNode
      class << self
        def recognize(*tokens)
          tokens.each do |token|
            class_name = token.to_s.downcase.camelcase
            const_set class_name, Class.new(Base)
          end
        end
      end
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

      recognize :request_word
      recognize :quoted_string
      recognize :register_reference
      recognize :number
      recognize :word 
      recognize :parameter 
      recognize :escape 
      recognize :insertion 
      recognize :parenthesized_sentence
      recognize :whitespace 
      recognize :end_of_line
      recognize :operator
      recognize :sentence_ending
      recognize :other
    end
  end
end