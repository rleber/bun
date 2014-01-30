#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

module Bun
  class Roff
    class StackUnderflow < RuntimeError; end

    class Thing < Hash 
      attr_accessor :roff
      def initialize(roff, options={})
        super()
        @roff = roff
        options.keys.each {|k| self.send("#{k}=", options[k])}
        self[:type] = type
      end

      def type
        self.class.to_s.sub(/.*::/,'').gsub(/(?<!^)([A-Z])/,'_\1').downcase.to_sym
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

    class Macro < Thing
      # TODO Wrong approach: push the Macro onto the stack of sources
      def invoke(*arguments)
        macro_context = roff.context_for_macro(self, *arguments)
        Roff.copy_state self, macro_context
        roff.push macro_context
      end
    end

    class Value < Thing
    end

    class Context < Thing
      # The context encapsulates information about what we're roffing:
      #   Current input line
      #   Current input line number
      #   Type of the frame
      #   Name of the frame (e.g. macro name)
      #   Original file source
      #   Starting line number in source file (for error messages)
      #   Arguments
      # There are several kinds of stack frames, e.g.
      #   Text:   We are roffing from text (not a file)
      #   File:   We are roffing from a file
      #   Macro:  We are roffing from a macro
      #   String: We are inserting a string (?)
      attr_accessor :macro

      def initialize(roff, options={})
        super
        @macro = options[:macro]
      end

      def at_bottom
        false
      end

      def arguments
        macro.arguments
      end

      def context_type
        type.to_s.sub(/_context/,'').to_sym
      end
    end

    class BaseContext  < Context
      def macro
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
    class MacroContext < Context
      attr_accessor :arguments
      def initialize(roff, options={})
        super
        @arguments = options[:arguments]
      end

      def macro
        self
      end
    end
  end
end
