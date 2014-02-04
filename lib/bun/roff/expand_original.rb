#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

module Bun
  class Roff
    def expand(line, options={})
      macro_arguments = self.arguments
      line = line.dup # So we don't change the original version of the line
      original_line = line.dup
      # TODO could move these and only change them when the characters do
      insert_pattern = self.insert_pattern
      insert_escape_pattern = self.insert_escape_pattern
      page_number_pattern = self.page_number_pattern
      parameter_pattern = self.parameter_pattern
      parameter_escape_pattern = self.parameter_escape_pattern
      changes = 0
      if (self.expand_parameters || options[:expand_parameters]) \
          && (options[:expand_parameters]!=false) \
          && macro_arguments
        line = expand_item(line, parameter_character, parameter_pattern, parameter_escape_pattern) do |match|
          changes += 1
          macro_arguments[(match[1..-1].to_i)-1]
        end
      end
      if (self.expand_substitutions || options[:expand_substitutions]) \
          && options[:expand_substitutions]!=false
        line = expand_item(line, @insert_character, insert_pattern, insert_escape_pattern) do |match|
          v = value_of(match[2..-2])
          if v.nil?
            match
          else
            changes += 1
            v.to_s
          end
        end
      end
      line = expand_item(line, @insert_character, page_number_pattern, insert_escape_pattern) do |match|
        changes += 1
        page_number.to_s
      end
      split_lines(line)
    end

    def expand_item(line, chars, pat, escape_pat, &blk)
      line.gsub(pat) {|match| yield(match) }.gsub(escape_pat, chars.to_s)
    end

    def insert_pattern
      substitution_pattern(@insert_character, @insert_escape, /\(([^)]*)\)/)
    end

    def page_number_pattern
      substitution_pattern(@insert_character, @insert_escape, /\(#{Regexp.escape(PAGE_NUMBER_CHARACTER)}\)/)
    end

    def insert_escape_pattern
      escape_pattern(@insert_escape)
    end

    def parameter_pattern
      substitution_pattern(parameter_character, parameter_escape, /(\d+)/)
    end

    def parameter_escape_pattern
      escape_pattern(parameter_escape)
    end

    def substitution_pattern(regular, escape, substitution_pat)
      if regular.to_s == ''
        /\Zx/ # Never matches
      elsif escape.to_s == ''
        /(#{Regexp.escape(regular)}#{substitution_pat})/
      else
        /(#{Regexp.escape(regular)}(?<!#{Regexp.escape(escape)})#{substitution_pat})/
      end
    end

    def escape_pattern(esc)
      if esc.to_s == ''
        /\Zx/ # Never matches
      else
        /#{Regexp.escape(esc)}/
      end
    end
    def display_match(match=$~)
      match.pre_match + '[[' + match[0] + ']]' + match.post_match
    end
  end
end
