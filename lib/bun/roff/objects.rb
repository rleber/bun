#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

class Fixnum
  ROMAN_NUMBERS = {
    1000 => "M",  
     900 => "CM",  
     500 => "D",  
     400 => "CD",
     100 => "C",  
      90 => "XC",  
      50 => "L",  
      40 => "XL",  
      10 => "X",  
        9 => "IX",  
        5 => "V",  
        4 => "IV",  
        1 => "I",  
        0 => "",  
  }

  def _roman
    return '' if self == 0
    av = abs
    ROMAN_NUMBERS.each do |value, letter|
      return ( letter * (av / value)) << (av % value)._roman if value <= av
    end
    (av % value)._roman
  end
  protected :_roman

  def roman
    return '0' if self == 0
    text = abs._roman
    text = '-' + text if self<0
    text
  end  

  def ordinal
    av = abs
    tens, digits = av.divmod(10)
    tens = tens % 10
    suffix = if tens == 1
      "th" # tenth, eleventh, twelfth... nineteenth
    else
      %w{th st nd rd th th th th th th}[digits]
    end
    self.to_s + suffix
  end

  def alphabetic
    return '0' if self==0
    av = abs
    repeat, char = (av-1).divmod(26)
    text = ('a'.ord + char).chr * (repeat+1)
    text = '-' + text if self < 0
    text
  end
end

module Bun
  class Roff
    class StackUnderflow < RuntimeError; end
    class BadExpression < RuntimeError; end

    class Thing < Hash 
      attr_accessor :roff
      def initialize(roff, options={})
        super()
        @roff = roff
        options.keys.each {|k| self.send("#{k}=", options[k])}
        self[:type] = type
      end

      def type
        self.class.to_s.sub(/.*::/,'').underscore.to_sym
      end

      def method_missing(meth, *args, &blk)
        raise ArgumentError, "Unexpected block for dynamic method #{meth}" if block_given?
        if meth.to_s =~ /(.*)=$/
          raise ArgumentError, "Wrong number of arguments to #{meth} (#{args.size} for 1)" unless args.size==1
          self[$1.to_sym] = args.first
        else
          raise ArgumentError, "Wrong number of arguments to #{meth} (#{args.size} for 0)" unless args.size==0
          self[meth.to_sym]
        end
      end
    end

    class Register < Thing
      # TODO Wrong approach: push the Register onto the stack of sources
      def invoke(*arguments)
        if self[:data_type] == :number
          v = self.formatted
          [ParsedNode.create(:number, text: v, value: self[:value], interval: 0...0)]
        else
          register_context = roff.context_for_register(self, *arguments)
          Roff.copy_state self, register_context
          roff.push register_context
          tokens = self[:lines].flatten.map do |token|
            if token.type == :parameter 
              arguments[token.value-1]
            else
              token
            end
          end
          roff.pop
          tokens
        end
      end

      def formatted
        v = self[:value]
        case f=self[:format]
        when /^(0+)1$/
          "%0#{$1.size+1}d" % v
        when /^(z+)1$/
          "%#{$1.size+1}d" % v
        when "o","O" # Ordinal numbers
          text = v.ordinal
          text.upcase! if f=="O"
          text
        when "i", "I" # Roman numerals
          text = v.roman
          text.downcase! if f=="i"
          text
        when "a", "A" # Alphabetic
          text = v.alphabetic
          text.upcase! if f=="A"
          text
        else
          v.to_s
        end
      end
    end

    class Context < Thing
      # The context encapsulates information about what we're roffing:
      #   Current input line
      #   Current input line number
      #   Type of the frame
      #   Name of the frame (e.g. register name)
      #   Original file source
      #   Starting line number in source file (for error messages)
      #   Arguments
      # There are several kinds of stack frames, e.g.
      #   Text:     We are roffing from text (not a file)
      #   File:     We are roffing from a file
      #   Register: We are roffing from a register
      #   String:   We are inserting a string (?)
      attr_accessor :register

      def initialize(roff, options={})
        super
        @register = options[:register]
      end

      def at_bottom
        false
      end

      def arguments
        register.arguments
      end

      def context_type
        type.to_s.sub(/_context/,'').to_sym
      end
    end

    class BaseContext  < Context
      def register
        self
      end

      def at_bottom
        true
      end

      def arguments
        nil
      end
    end
    class FileContext  < Context; end
    class TextContext  < Context; end
    class RegisterContext < Context
      attr_accessor :arguments
      def initialize(roff, options={})
        super
        @arguments = options[:arguments]
      end

      def register
        self
      end
    end
  end
end
