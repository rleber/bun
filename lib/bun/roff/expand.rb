#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

module Bun
  class Roff
    def expand(line, options={})
      register_arguments = self.arguments
      line = line.dup # So we don't change the original version of the line
      original_line = line.dup
      # TODO could move these and only change them when the characters do
      expanded_line = []
      toks = line.tokens.dup
      while toks.size > 0
        token = toks.shift
        if token.type == :insertion
          if (self.expand_substitutions || options[:expand_substitutions]) \
              && options[:expand_substitutions]!=false
            # Expand insertion
            invocation = token.value
            debug "invocation: #{invocation.inspect}"
            call = request_words(invocation)
            debug "call: #{call.inspect}"
            syntax "Missing request name" if call.size == 0
            register = call.shift
            syntax "Expected register name, found #{register.inspect}" unless register.type==:word
            defn = get_definition(register)
            toks = defn.invoke(*call) + toks
          end
        else
          expanded_line << token
        end
      end
      split_parsed_lines(expanded_line)
    end

  end
end
