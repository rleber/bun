# Treetop grammar for Roff input lines
# Autogenerated from a Treetop grammar. Edits may be lost.


# Compile using:
#   tt lib/bun/roff/expand.treetop -o lib/bun/roff/expand_treetop_parser.rb

# This grammar is finicky; mess with it at your peril

# Future enhancement:
#   - Recognize .requests
#   - Set value of numbers to integer value
#   - Store position range
#   - Recognize trailing sentence endings?

module RoffInput
  include Treetop::Runtime

  def root
    @root ||= :input
  end

  module Input0
    def content
      elements[0]
    end
  end

  module Input1
  		def expand
  			content.elements.first.expand
			end
  end

  def _nt_input
    start_index = index
    if node_cache[:input].has_key?(index)
      cached = node_cache[:input][index]
      if cached
        cached = SyntaxNode.new(input, index...(index + 1)) if cached == true
        @index = cached.interval.end
      end
      return cached
    end

    i0, s0 = index, []
    s1, i1 = [], index
    loop do
      i2 = index
      r3 = _nt_request
      if r3
        r2 = r3
      else
        r4 = _nt_line
        if r4
          r2 = r4
        else
          @index = i2
          r2 = nil
        end
      end
      if r2
        s1 << r2
      else
        break
      end
      if s1.size == 1
        break
      end
    end
    if s1.size < 1
      @index = i1
      r1 = nil
    else
      r1 = instantiate_node(SyntaxNode,input, i1...index, s1)
    end
    s0 << r1
    if s0.last
      r0 = instantiate_node(SyntaxNode,input, i0...index, s0)
      r0.extend(Input0)
      r0.extend(Input1)
    else
      @index = i0
      r0 = nil
    end

    node_cache[:input][start_index] = r0

    r0
  end

  module Request0
    def request_word
      elements[0]
    end

    def line
      elements[1]
    end
  end

  module Request1
  		def expand
  			request_word.expand + line.expand
			end
  end

  def _nt_request
    start_index = index
    if node_cache[:request].has_key?(index)
      cached = node_cache[:request][index]
      if cached
        cached = SyntaxNode.new(input, index...(index + 1)) if cached == true
        @index = cached.interval.end
      end
      return cached
    end

    i0, s0 = index, []
    r1 = _nt_request_word
    s0 << r1
    if r1
      r2 = _nt_line
      s0 << r2
    end
    if s0.last
      r0 = instantiate_node(SyntaxNode,input, i0...index, s0)
      r0.extend(Request0)
      r0.extend(Request1)
    else
      @index = i0
      r0 = nil
    end

    node_cache[:request][start_index] = r0

    r0
  end

  module RequestWord0
    def command_character
      elements[0]
    end

    def word
      elements[1]
    end
  end

  module RequestWord1
  		def expand
  			[{type: :request_word, value: text_value}]
			end
  end

  def _nt_request_word
    start_index = index
    if node_cache[:request_word].has_key?(index)
      cached = node_cache[:request_word][index]
      if cached
        cached = SyntaxNode.new(input, index...(index + 1)) if cached == true
        @index = cached.interval.end
      end
      return cached
    end

    i0, s0 = index, []
    r1 = _nt_command_character
    s0 << r1
    if r1
      r2 = _nt_word
      s0 << r2
    end
    if s0.last
      r0 = instantiate_node(SyntaxNode,input, i0...index, s0)
      r0.extend(RequestWord0)
      r0.extend(RequestWord1)
    else
      @index = i0
      r0 = nil
    end

    node_cache[:request_word][start_index] = r0

    r0
  end

  def _nt_command_character
    start_index = index
    if node_cache[:command_character].has_key?(index)
      cached = node_cache[:command_character][index]
      if cached
        cached = SyntaxNode.new(input, index...(index + 1)) if cached == true
        @index = cached.interval.end
      end
      return cached
    end

    if has_terminal?(".", false, index)
      r0 = instantiate_node(SyntaxNode,input, index...(index + 1))
      @index += 1
    else
      terminal_parse_failure(".")
      r0 = nil
    end

    node_cache[:command_character][start_index] = r0

    r0
  end

  module Line0
    def content
      elements[0]
    end

    def end_of_line
      elements[1]
    end
  end

  module Line1
			def expand
				content.elements.flat_map{|e| e.expand}
			end
  end

  def _nt_line
    start_index = index
    if node_cache[:line].has_key?(index)
      cached = node_cache[:line][index]
      if cached
        cached = SyntaxNode.new(input, index...(index + 1)) if cached == true
        @index = cached.interval.end
      end
      return cached
    end

    i0, s0 = index, []
    s1, i1 = [], index
    loop do
      r2 = _nt_sentence_part
      if r2
        s1 << r2
      else
        break
      end
    end
    r1 = instantiate_node(SyntaxNode,input, i1...index, s1)
    s0 << r1
    if r1
      r3 = _nt_end_of_line
      s0 << r3
    end
    if s0.last
      r0 = instantiate_node(SyntaxNode,input, i0...index, s0)
      r0.extend(Line0)
      r0.extend(Line1)
    else
      @index = i0
      r0 = nil
    end

    node_cache[:line][start_index] = r0

    r0
  end

  module SentencePart0
			def expand
				elements.first.expand
			end
  end

  def _nt_sentence_part
    start_index = index
    if node_cache[:sentence_part].has_key?(index)
      cached = node_cache[:sentence_part][index]
      if cached
        cached = SyntaxNode.new(input, index...(index + 1)) if cached == true
        @index = cached.interval.end
      end
      return cached
    end

    s0, i0 = [], index
    loop do
      i1 = index
      r2 = _nt_register_reference
      if r2
        r1 = r2
      else
        r3 = _nt_nested_sentence_part
        if r3
          r1 = r3
        else
          r4 = _nt_paren
          if r4
            r1 = r4
          else
            r5 = _nt_other_character
            if r5
              r1 = r5
            else
              @index = i1
              r1 = nil
            end
          end
        end
      end
      if r1
        s0 << r1
      else
        break
      end
      if s0.size == 1
        break
      end
    end
    if s0.size < 1
      @index = i0
      r0 = nil
    else
      r0 = instantiate_node(SyntaxNode,input, i0...index, s0)
      r0.extend(SentencePart0)
    end

    node_cache[:sentence_part][start_index] = r0

    r0
  end

  module Paren0
			def expand
				[{type: :other, value: text_value}]
			end
  end

  def _nt_paren
    start_index = index
    if node_cache[:paren].has_key?(index)
      cached = node_cache[:paren][index]
      if cached
        cached = SyntaxNode.new(input, index...(index + 1)) if cached == true
        @index = cached.interval.end
      end
      return cached
    end

    s0, i0 = [], index
    loop do
      i1 = index
      if has_terminal?('(', false, index)
        r2 = instantiate_node(SyntaxNode,input, index...(index + 1))
        @index += 1
      else
        terminal_parse_failure('(')
        r2 = nil
      end
      if r2
        r1 = r2
      else
        if has_terminal?(')', false, index)
          r3 = instantiate_node(SyntaxNode,input, index...(index + 1))
          @index += 1
        else
          terminal_parse_failure(')')
          r3 = nil
        end
        if r3
          r1 = r3
        else
          @index = i1
          r1 = nil
        end
      end
      if r1
        s0 << r1
      else
        break
      end
      if s0.size == 1
        break
      end
    end
    if s0.size < 1
      @index = i0
      r0 = nil
    else
      r0 = instantiate_node(SyntaxNode,input, i0...index, s0)
      r0.extend(Paren0)
    end

    node_cache[:paren][start_index] = r0

    r0
  end

  module QuotedString0
    def quote_character1
      elements[0]
    end

    def quote_character2
      elements[2]
    end
  end

  module QuotedString1
    	def expand
    		[{type: :quoted_string, value: text_value}]
    	end
  end

  def _nt_quoted_string
    start_index = index
    if node_cache[:quoted_string].has_key?(index)
      cached = node_cache[:quoted_string][index]
      if cached
        cached = SyntaxNode.new(input, index...(index + 1)) if cached == true
        @index = cached.interval.end
      end
      return cached
    end

    i0, s0 = index, []
    r1 = _nt_quote_character
    s0 << r1
    if r1
      s2, i2 = [], index
      loop do
        r3 = _nt_quoted_string_atom
        if r3
          s2 << r3
        else
          break
        end
      end
      r2 = instantiate_node(SyntaxNode,input, i2...index, s2)
      s0 << r2
      if r2
        r4 = _nt_quote_character
        s0 << r4
      end
    end
    if s0.last
      r0 = instantiate_node(SyntaxNode,input, i0...index, s0)
      r0.extend(QuotedString0)
      r0.extend(QuotedString1)
    else
      @index = i0
      r0 = nil
    end

    node_cache[:quoted_string][start_index] = r0

    r0
  end

  def _nt_quoted_string_atom
    start_index = index
    if node_cache[:quoted_string_atom].has_key?(index)
      cached = node_cache[:quoted_string_atom][index]
      if cached
        cached = SyntaxNode.new(input, index...(index + 1)) if cached == true
        @index = cached.interval.end
      end
      return cached
    end

    i0 = index
    r1 = _nt_escaped_quote
    if r1
      r0 = r1
    else
      r2 = _nt_non_quote_character
      if r2
        r0 = r2
      else
        @index = i0
        r0 = nil
      end
    end

    node_cache[:quoted_string_atom][start_index] = r0

    r0
  end

  module EscapedQuote0
    def quote_character1
      elements[0]
    end

    def quote_character2
      elements[1]
    end
  end

  def _nt_escaped_quote
    start_index = index
    if node_cache[:escaped_quote].has_key?(index)
      cached = node_cache[:escaped_quote][index]
      if cached
        cached = SyntaxNode.new(input, index...(index + 1)) if cached == true
        @index = cached.interval.end
      end
      return cached
    end

    i0, s0 = index, []
    r1 = _nt_quote_character
    s0 << r1
    if r1
      r2 = _nt_quote_character
      s0 << r2
    end
    if s0.last
      r0 = instantiate_node(SyntaxNode,input, i0...index, s0)
      r0.extend(EscapedQuote0)
    else
      @index = i0
      r0 = nil
    end

    node_cache[:escaped_quote][start_index] = r0

    r0
  end

  module NonQuoteCharacter0
  end

  def _nt_non_quote_character
    start_index = index
    if node_cache[:non_quote_character].has_key?(index)
      cached = node_cache[:non_quote_character][index]
      if cached
        cached = SyntaxNode.new(input, index...(index + 1)) if cached == true
        @index = cached.interval.end
      end
      return cached
    end

    i0, s0 = index, []
    i1 = index
    r2 = _nt_quote_character
    if r2
      r1 = nil
    else
      @index = i1
      r1 = instantiate_node(SyntaxNode,input, index...index)
    end
    s0 << r1
    if r1
      i3 = index
      r4 = _nt_end_of_line
      if r4
        r3 = nil
      else
        @index = i3
        r3 = instantiate_node(SyntaxNode,input, index...index)
      end
      s0 << r3
      if r3
        if index < input_length
          r5 = instantiate_node(SyntaxNode,input, index...(index + 1))
          @index += 1
        else
          terminal_parse_failure("any character")
          r5 = nil
        end
        s0 << r5
      end
    end
    if s0.last
      r0 = instantiate_node(SyntaxNode,input, i0...index, s0)
      r0.extend(NonQuoteCharacter0)
    else
      @index = i0
      r0 = nil
    end

    node_cache[:non_quote_character][start_index] = r0

    r0
  end

  def _nt_quote_character
    start_index = index
    if node_cache[:quote_character].has_key?(index)
      cached = node_cache[:quote_character][index]
      if cached
        cached = SyntaxNode.new(input, index...(index + 1)) if cached == true
        @index = cached.interval.end
      end
      return cached
    end

    if has_terminal?('"', false, index)
      r0 = instantiate_node(SyntaxNode,input, index...(index + 1))
      @index += 1
    else
      terminal_parse_failure('"')
      r0 = nil
    end

    node_cache[:quote_character][start_index] = r0

    r0
  end

  module RegisterReference0
    def word
      elements[1]
    end

  end

  module RegisterReference1
			def expand
				res = [{type: :register_reference, value: word.expand[0][:value]}]
			end
  end

  def _nt_register_reference
    start_index = index
    if node_cache[:register_reference].has_key?(index)
      cached = node_cache[:register_reference][index]
      if cached
        cached = SyntaxNode.new(input, index...(index + 1)) if cached == true
        @index = cached.interval.end
      end
      return cached
    end

    i0, s0 = index, []
    if has_terminal?('(', false, index)
      r1 = instantiate_node(SyntaxNode,input, index...(index + 1))
      @index += 1
    else
      terminal_parse_failure('(')
      r1 = nil
    end
    s0 << r1
    if r1
      r2 = _nt_word
      s0 << r2
      if r2
        if has_terminal?(')', false, index)
          r3 = instantiate_node(SyntaxNode,input, index...(index + 1))
          @index += 1
        else
          terminal_parse_failure(')')
          r3 = nil
        end
        s0 << r3
      end
    end
    if s0.last
      r0 = instantiate_node(SyntaxNode,input, i0...index, s0)
      r0.extend(RegisterReference0)
      r0.extend(RegisterReference1)
    else
      @index = i0
      r0 = nil
    end

    node_cache[:register_reference][start_index] = r0

    r0
  end

  module Number0
			def expand
				[{type: :number, value: text_value}]
			end
  end

  def _nt_number
    start_index = index
    if node_cache[:number].has_key?(index)
      cached = node_cache[:number][index]
      if cached
        cached = SyntaxNode.new(input, index...(index + 1)) if cached == true
        @index = cached.interval.end
      end
      return cached
    end

    s0, i0 = [], index
    loop do
      if has_terminal?('\G[0-9]', true, index)
        r1 = true
        @index += 1
      else
        r1 = nil
      end
      if r1
        s0 << r1
      else
        break
      end
    end
    if s0.empty?
      @index = i0
      r0 = nil
    else
      r0 = instantiate_node(SyntaxNode,input, i0...index, s0)
      r0.extend(Number0)
    end

    node_cache[:number][start_index] = r0

    r0
  end

  module Word0
  end

  module Word1
	  	def expand
	  		[{type: :word, value: text_value}]
  		end
  end

  def _nt_word
    start_index = index
    if node_cache[:word].has_key?(index)
      cached = node_cache[:word][index]
      if cached
        cached = SyntaxNode.new(input, index...(index + 1)) if cached == true
        @index = cached.interval.end
      end
      return cached
    end

    i0, s0 = index, []
    if has_terminal?('\G[a-zA-Z#%_]', true, index)
      r1 = true
      @index += 1
    else
      r1 = nil
    end
    s0 << r1
    if r1
      s2, i2 = [], index
      loop do
        i3 = index
        if has_terminal?('\G[a-zA-Z0-9#%_]', true, index)
          r4 = true
          @index += 1
        else
          r4 = nil
        end
        if r4
          r3 = r4
        else
          r5 = _nt_hyphenation_character
          if r5
            r3 = r5
          else
            @index = i3
            r3 = nil
          end
        end
        if r3
          s2 << r3
        else
          break
        end
      end
      r2 = instantiate_node(SyntaxNode,input, i2...index, s2)
      s0 << r2
    end
    if s0.last
      r0 = instantiate_node(SyntaxNode,input, i0...index, s0)
      r0.extend(Word0)
      r0.extend(Word1)
    else
      @index = i0
      r0 = nil
    end

    node_cache[:word][start_index] = r0

    r0
  end

  module Parameter0
    def parameter_character
      elements[0]
    end

    def number
      elements[1]
    end
  end

  module Parameter1
			def expand
	  		[{type: :parameter, value: text_value}]
  		end
  end

  def _nt_parameter
    start_index = index
    if node_cache[:parameter].has_key?(index)
      cached = node_cache[:parameter][index]
      if cached
        cached = SyntaxNode.new(input, index...(index + 1)) if cached == true
        @index = cached.interval.end
      end
      return cached
    end

    i0, s0 = index, []
    r1 = _nt_parameter_character
    s0 << r1
    if r1
      r2 = _nt_number
      s0 << r2
    end
    if s0.last
      r0 = instantiate_node(SyntaxNode,input, i0...index, s0)
      r0.extend(Parameter0)
      r0.extend(Parameter1)
    else
      @index = i0
      r0 = nil
    end

    node_cache[:parameter][start_index] = r0

    r0
  end

  def _nt_parameter_character
    start_index = index
    if node_cache[:parameter_character].has_key?(index)
      cached = node_cache[:parameter_character][index]
      if cached
        cached = SyntaxNode.new(input, index...(index + 1)) if cached == true
        @index = cached.interval.end
      end
      return cached
    end

    if has_terminal?('@', false, index)
      r0 = instantiate_node(SyntaxNode,input, index...(index + 1))
      @index += 1
    else
      terminal_parse_failure('@')
      r0 = nil
    end

    node_cache[:parameter_character][start_index] = r0

    r0
  end

  module Escape0
    def insertion_character
      elements[0]
    end

  end

  module Escape1
			def expand
				[{type: :escape, value: text_value}]
			end
  end

  def _nt_escape
    start_index = index
    if node_cache[:escape].has_key?(index)
      cached = node_cache[:escape][index]
      if cached
        cached = SyntaxNode.new(input, index...(index + 1)) if cached == true
        @index = cached.interval.end
      end
      return cached
    end

    i0, s0 = index, []
    r1 = _nt_insertion_character
    s0 << r1
    if r1
      i2 = index
      i3 = index
      if has_terminal?('(', false, index)
        r4 = instantiate_node(SyntaxNode,input, index...(index + 1))
        @index += 1
      else
        terminal_parse_failure('(')
        r4 = nil
      end
      if r4
        r3 = r4
      else
        r5 = _nt_end_of_line
        if r5
          r3 = r5
        else
          @index = i3
          r3 = nil
        end
      end
      if r3
        r2 = nil
      else
        @index = i2
        r2 = instantiate_node(SyntaxNode,input, index...index)
      end
      s0 << r2
      if r2
        if index < input_length
          r6 = instantiate_node(SyntaxNode,input, index...(index + 1))
          @index += 1
        else
          terminal_parse_failure("any character")
          r6 = nil
        end
        s0 << r6
      end
    end
    if s0.last
      r0 = instantiate_node(SyntaxNode,input, i0...index, s0)
      r0.extend(Escape0)
      r0.extend(Escape1)
    else
      @index = i0
      r0 = nil
    end

    node_cache[:escape][start_index] = r0

    r0
  end

  module Insertion0
    def insertion_character
      elements[0]
    end

    def nested_sentence
      elements[2]
    end

  end

  module Insertion1
    	def expand
    		[{type: :insertion, value: nested_sentence.expand}]
  		end
  end

  def _nt_insertion
    start_index = index
    if node_cache[:insertion].has_key?(index)
      cached = node_cache[:insertion][index]
      if cached
        cached = SyntaxNode.new(input, index...(index + 1)) if cached == true
        @index = cached.interval.end
      end
      return cached
    end

    i0, s0 = index, []
    r1 = _nt_insertion_character
    s0 << r1
    if r1
      if has_terminal?('(', false, index)
        r2 = instantiate_node(SyntaxNode,input, index...(index + 1))
        @index += 1
      else
        terminal_parse_failure('(')
        r2 = nil
      end
      s0 << r2
      if r2
        r3 = _nt_nested_sentence
        s0 << r3
        if r3
          if has_terminal?(')', false, index)
            r4 = instantiate_node(SyntaxNode,input, index...(index + 1))
            @index += 1
          else
            terminal_parse_failure(')')
            r4 = nil
          end
          s0 << r4
        end
      end
    end
    if s0.last
      r0 = instantiate_node(SyntaxNode,input, i0...index, s0)
      r0.extend(Insertion0)
      r0.extend(Insertion1)
    else
      @index = i0
      r0 = nil
    end

    node_cache[:insertion][start_index] = r0

    r0
  end

  module ParenthesizedSentence0
    def nested_sentence
      elements[1]
    end

  end

  module ParenthesizedSentence1
			def expand
				[{type: :parenthesized_sentence, value: nested_sentence.expand}]
			end
  end

  def _nt_parenthesized_sentence
    start_index = index
    if node_cache[:parenthesized_sentence].has_key?(index)
      cached = node_cache[:parenthesized_sentence][index]
      if cached
        cached = SyntaxNode.new(input, index...(index + 1)) if cached == true
        @index = cached.interval.end
      end
      return cached
    end

    i0, s0 = index, []
    if has_terminal?('(', false, index)
      r1 = instantiate_node(SyntaxNode,input, index...(index + 1))
      @index += 1
    else
      terminal_parse_failure('(')
      r1 = nil
    end
    s0 << r1
    if r1
      r2 = _nt_nested_sentence
      s0 << r2
      if r2
        if has_terminal?(')', false, index)
          r3 = instantiate_node(SyntaxNode,input, index...(index + 1))
          @index += 1
        else
          terminal_parse_failure(')')
          r3 = nil
        end
        s0 << r3
      end
    end
    if s0.last
      r0 = instantiate_node(SyntaxNode,input, i0...index, s0)
      r0.extend(ParenthesizedSentence0)
      r0.extend(ParenthesizedSentence1)
    else
      @index = i0
      r0 = nil
    end

    node_cache[:parenthesized_sentence][start_index] = r0

    r0
  end

  module NestedSentence0
			def expand
				nested_sentence_parts.expand
			end
  end

  def _nt_nested_sentence
    start_index = index
    if node_cache[:nested_sentence].has_key?(index)
      cached = node_cache[:nested_sentence][index]
      if cached
        cached = SyntaxNode.new(input, index...(index + 1)) if cached == true
        @index = cached.interval.end
      end
      return cached
    end

    r0 = _nt_nested_sentence_parts

    node_cache[:nested_sentence][start_index] = r0

    r0
  end

  module NestedSentenceParts0
    def first
      elements[0]
    end

    def remainder
      elements[1]
    end
  end

  module NestedSentenceParts1
			def expand
				first.expand + remainder.elements.flat_map {|e| e.expand}
			end
  end

  def _nt_nested_sentence_parts
    start_index = index
    if node_cache[:nested_sentence_parts].has_key?(index)
      cached = node_cache[:nested_sentence_parts][index]
      if cached
        cached = SyntaxNode.new(input, index...(index + 1)) if cached == true
        @index = cached.interval.end
      end
      return cached
    end

    i0, s0 = index, []
    r1 = _nt_nested_sentence_part
    s0 << r1
    if r1
      s2, i2 = [], index
      loop do
        r3 = _nt_nested_sentence_part
        if r3
          s2 << r3
        else
          break
        end
      end
      r2 = instantiate_node(SyntaxNode,input, i2...index, s2)
      s0 << r2
    end
    if s0.last
      r0 = instantiate_node(SyntaxNode,input, i0...index, s0)
      r0.extend(NestedSentenceParts0)
      r0.extend(NestedSentenceParts1)
    else
      @index = i0
      r0 = nil
    end

    node_cache[:nested_sentence_parts][start_index] = r0

    r0
  end

  module NestedSentencePart0
			def expand
				elements.first.expand
			end
  end

  def _nt_nested_sentence_part
    start_index = index
    if node_cache[:nested_sentence_part].has_key?(index)
      cached = node_cache[:nested_sentence_part][index]
      if cached
        cached = SyntaxNode.new(input, index...(index + 1)) if cached == true
        @index = cached.interval.end
      end
      return cached
    end

    s0, i0 = [], index
    loop do
      i1 = index
      r2 = _nt_parenthesized_sentence
      if r2
        r1 = r2
      else
        r3 = _nt_nested_sentence_atom
        if r3
          r1 = r3
        else
          @index = i1
          r1 = nil
        end
      end
      if r1
        s0 << r1
      else
        break
      end
      if s0.size == 1
        break
      end
    end
    if s0.size < 1
      @index = i0
      r0 = nil
    else
      r0 = instantiate_node(SyntaxNode,input, i0...index, s0)
      r0.extend(NestedSentencePart0)
    end

    node_cache[:nested_sentence_part][start_index] = r0

    r0
  end

  module NestedSentenceAtom0
			def expand
				elements.first.expand
			end
  end

  def _nt_nested_sentence_atom
    start_index = index
    if node_cache[:nested_sentence_atom].has_key?(index)
      cached = node_cache[:nested_sentence_atom][index]
      if cached
        cached = SyntaxNode.new(input, index...(index + 1)) if cached == true
        @index = cached.interval.end
      end
      return cached
    end

    s0, i0 = [], index
    loop do
      i1 = index
      r2 = _nt_whitespace
      if r2
        r1 = r2
      else
        r3 = _nt_quoted_string
        if r3
          r1 = r3
        else
          r4 = _nt_number
          if r4
            r1 = r4
          else
            r5 = _nt_word
            if r5
              r1 = r5
            else
              r6 = _nt_parameter
              if r6
                r1 = r6
              else
                r7 = _nt_escape
                if r7
                  r1 = r7
                else
                  r8 = _nt_insertion
                  if r8
                    r1 = r8
                  else
                    r9 = _nt_operator
                    if r9
                      r1 = r9
                    else
                      @index = i1
                      r1 = nil
                    end
                  end
                end
              end
            end
          end
        end
      end
      if r1
        s0 << r1
      else
        break
      end
      if s0.size == 1
        break
      end
    end
    if s0.size < 1
      @index = i0
      r0 = nil
    else
      r0 = instantiate_node(SyntaxNode,input, i0...index, s0)
      r0.extend(NestedSentenceAtom0)
    end

    node_cache[:nested_sentence_atom][start_index] = r0

    r0
  end

  module InsertionCharacter0
			def expand
				[{type: :insertion_character, value: text_value}]
			end
  end

  def _nt_insertion_character
    start_index = index
    if node_cache[:insertion_character].has_key?(index)
      cached = node_cache[:insertion_character][index]
      if cached
        cached = SyntaxNode.new(input, index...(index + 1)) if cached == true
        @index = cached.interval.end
      end
      return cached
    end

    if has_terminal?('^', false, index)
      r0 = instantiate_node(SyntaxNode,input, index...(index + 1))
      r0.extend(InsertionCharacter0)
      @index += 1
    else
      terminal_parse_failure('^')
      r0 = nil
    end

    node_cache[:insertion_character][start_index] = r0

    r0
  end

  module HyphenationCharacter0
			def expand
				[{type: :hyphenation_character, value: text_value}]
			end
  end

  def _nt_hyphenation_character
    start_index = index
    if node_cache[:hyphenation_character].has_key?(index)
      cached = node_cache[:hyphenation_character][index]
      if cached
        cached = SyntaxNode.new(input, index...(index + 1)) if cached == true
        @index = cached.interval.end
      end
      return cached
    end

    if has_terminal?("`", false, index)
      r0 = instantiate_node(SyntaxNode,input, index...(index + 1))
      r0.extend(HyphenationCharacter0)
      @index += 1
    else
      terminal_parse_failure("`")
      r0 = nil
    end

    node_cache[:hyphenation_character][start_index] = r0

    r0
  end

  module Whitespace0
			def expand
				[{type: :whitespace, value: text_value}]
			end
  end

  def _nt_whitespace
    start_index = index
    if node_cache[:whitespace].has_key?(index)
      cached = node_cache[:whitespace][index]
      if cached
        cached = SyntaxNode.new(input, index...(index + 1)) if cached == true
        @index = cached.interval.end
      end
      return cached
    end

    s0, i0 = [], index
    loop do
      if has_terminal?('\G[ \\t]', true, index)
        r1 = true
        @index += 1
      else
        r1 = nil
      end
      if r1
        s0 << r1
      else
        break
      end
    end
    if s0.empty?
      @index = i0
      r0 = nil
    else
      r0 = instantiate_node(SyntaxNode,input, i0...index, s0)
      r0.extend(Whitespace0)
    end

    node_cache[:whitespace][start_index] = r0

    r0
  end

  module EndOfLine0
			def expand
				[{type: :end_of_line, value: text_value}]
			end
  end

  def _nt_end_of_line
    start_index = index
    if node_cache[:end_of_line].has_key?(index)
      cached = node_cache[:end_of_line][index]
      if cached
        cached = SyntaxNode.new(input, index...(index + 1)) if cached == true
        @index = cached.interval.end
      end
      return cached
    end

    if has_terminal?("\n", false, index)
      r0 = instantiate_node(SyntaxNode,input, index...(index + 1))
      r0.extend(EndOfLine0)
      @index += 1
    else
      terminal_parse_failure("\n")
      r0 = nil
    end

    node_cache[:end_of_line][start_index] = r0

    r0
  end

  module Operator0
			def expand
				[{type: :operator, value: text_value}]
			end
  end

  def _nt_operator
    start_index = index
    if node_cache[:operator].has_key?(index)
      cached = node_cache[:operator][index]
      if cached
        cached = SyntaxNode.new(input, index...(index + 1)) if cached == true
        @index = cached.interval.end
      end
      return cached
    end

    if has_terminal?('\G[-+*/<=>]', true, index)
      r0 = instantiate_node(SyntaxNode,input, index...(index + 1))
      r0.extend(Operator0)
      @index += 1
    else
      r0 = nil
    end

    node_cache[:operator][start_index] = r0

    r0
  end

  module OtherCharacter0
  end

  module OtherCharacter1
  		def expand
  			[{type: :other, value: text_value}]
			end
  end

  def _nt_other_character
    start_index = index
    if node_cache[:other_character].has_key?(index)
      cached = node_cache[:other_character][index]
      if cached
        cached = SyntaxNode.new(input, index...(index + 1)) if cached == true
        @index = cached.interval.end
      end
      return cached
    end

    s0, i0 = [], index
    loop do
      i1, s1 = index, []
      i2 = index
      i3 = index
      r4 = _nt_insertion_character
      if r4
        r3 = r4
      else
        r5 = _nt_quote_character
        if r5
          r3 = r5
        else
          r6 = _nt_parameter_character
          if r6
            r3 = r6
          else
            r7 = _nt_hyphenation_character
            if r7
              r3 = r7
            else
              if has_terminal?('\G[-()a-zA-Z0-9%#_+*/<=> \\t\\n]', true, index)
                r8 = true
                @index += 1
              else
                r8 = nil
              end
              if r8
                r3 = r8
              else
                @index = i3
                r3 = nil
              end
            end
          end
        end
      end
      if r3
        r2 = nil
      else
        @index = i2
        r2 = instantiate_node(SyntaxNode,input, index...index)
      end
      s1 << r2
      if r2
        if index < input_length
          r9 = instantiate_node(SyntaxNode,input, index...(index + 1))
          @index += 1
        else
          terminal_parse_failure("any character")
          r9 = nil
        end
        s1 << r9
      end
      if s1.last
        r1 = instantiate_node(SyntaxNode,input, i1...index, s1)
        r1.extend(OtherCharacter0)
      else
        @index = i1
        r1 = nil
      end
      if r1
        s0 << r1
      else
        break
      end
      if s0.size == 1
        break
      end
    end
    if s0.size < 1
      @index = i0
      r0 = nil
    else
      r0 = instantiate_node(SyntaxNode,input, i0...index, s0)
      r0.extend(OtherCharacter1)
    end

    node_cache[:other_character][start_index] = r0

    r0
  end

end

class RoffInputParser < Treetop::Runtime::CompiledParser
  include RoffInput
end

