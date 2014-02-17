#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

module Bun
  class Roff

    def convert_expression(base_value, *args)
      tokens = args.shift
      return tokens if tokens.is_a?(Integer) # Allow easy default value setting
      tokens = [tokens] unless tokens.is_a?(Array)
      tokens = preprocess_expression(tokens)
      label = args.shift || "?"
      ensure_not_end_of_line tokens, BadExpression, "Empty expression in #{label}"
      if tokens.first.type == :operator
        value = base_value
      else
        value = get_expression_value(tokens.first)
        tokens.shift
      end
      while tokens.size >0 && tokens.first.type != :end_of_line
        input_error BadExpression, "Expecting operator in #{label}, found #{tokens.first.type} #{tokens.first.text.inspect}", at: tokens.first.interval.begin \
          unless valid_operator?(tokens.first)
        operator = tokens.shift
        ensure_not_end_of_line tokens, BadExpression, "Empty expression in #{label}"
        value = perform_operator(value, operator, get_expression_value(tokens.first, label), label)
        tokens.shift
      end
      value
    end

    # Kludgy; separate grammar for expressions?
    def preprocess_expression(expression)
      loop do
        changes = 0
        new_expression = []
        expression.each do |token|
          if token.type == :word
            input_error BadExpression, "Found strange character #{token.text[0].inspect} in expression", at: token.interval.begin \
              unless token.text[0] == 'l' || token.text[0] == 's'
            if token.text.size == 1
              new_expression << token
            else
              new_expression << ParsedNode.create(:word, text: token.text[0], interval: (token.interval.begin...(token.interval.begin+2)))
              changes += 1
              input_error BadExpression, "Found strange character #{token.text[1].inspect} in expression", at: token.interval.begin+1 \
                unless token.text[1] =~ /[0-9]/
              next_token = token.text[1..-1][/^([0-9]+)/,1]
              remainder = $'
              new_expression << ParsedNode.create(:number, text: next_token, interval: (token.interval.begin+1)...(token.interval.begin+1+next_token.size))
              new_expression << ParsedNode.create(:word, text: remainder, interval: (token.interval.begin+1+next_token.size)...(token.interval.end)) \
                if remainder.size > 0
            end
          else
            new_expression << token
          end
        end
        expression = new_expression
        break if changes == 0
      end
      expression
    end

    def valid_operator?(token)
      %w{l s + - * / < > =}.include?(token.output_text)
    end

    def get_expression_value(arg, label="?")
      case arg.type
      when :number
        arg.value
      when :quoted_string
        arg.value.size
      else
        raise BadExpression, "Invalid operand in #{label}: #{arg.text}"
      end
    end

    def perform_operator(value1, operator, value2, label="?")
      case operator.value.to_s
      when "+"
        value1 + value2
      when "-"
        value1 - value2
      when "*"
        value1 * value2
      when "/"
        value1 / value2
      when "<"
        (value1 < value2) ? 1 : 0
      when "="
        (value1 == value2) ? 1 : 0
      when ">"
        (value1 > value2) ? 1 : 0
      when "l"
        [value1, value2].max
      when "s"
        [value1, value2].min
      else
        input_error BadExpression, "Unexpected operator in #{label}: #{operator}", at: operator.interval.begin
      end
    end

    def convert_string(arg, name)
      return arg if arg.is_a?(String) # Allow easy default value setting
      arg.output_text
    end

    def convert_integer(arg, name)
      return arg if arg.is_a?(Integer) # Allow easy default value setting
      err "!#{name} must be an integer. Found #{arg.inspect}" unless arg.type == :number
      i = arg.value
      err "!#{name} can't be negative" if i<0
      i 
    end
  end
end