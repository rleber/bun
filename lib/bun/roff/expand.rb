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
      line.tokens.each do |token|
        case token.type
        when :insertion
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
            defn.invoke(*call)
            debug "defn: #{defn.inspect}"

            expanded_line += invoke(token)
          end
        when :parameter 
          if (self.expand_parameters || options[:expand_parameters]) \
              && (options[:expand_parameters]!=false) \
              && register_arguments        
              # Expand parameter
            a = register_arguments[token.value-1]
            expanded_line += parse(a.value.to_s) if a
          else
            expanded_line << token
          end
        when :escape
          expanded_line << parse(token.value)
        else
          expanded_line << token
        end
      end
      split_parsed_lines(expanded_line)
    end

  end
end
