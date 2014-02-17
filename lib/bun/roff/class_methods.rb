#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

module Bun
  class Roff

    class << self
      # TODO Meaning of to should be:
      #   -      Process to STDOUT
      #   nil    Don't output; return the accumulated result as a string
      #   other  Process to this output path
      def process_file(from, to, options={})
        process_context(to, options) do |roff|
          roff.context_for_file(from)
        end
      end

      def process_text(text, to, options={})
        process_context(to, options) do |roff|
          roff.context_for_text(text)
        end
      end

      def process_context(to, options={}, &blk)
        dir = options.delete(:dir) || Dir.pwd
        Dir.chdir(dir) do
          roff = new(options)
          roff.push yield(roff)
          roff.process(to, options)
        end
      end

      def copy_state(from, to)
        to.parameter_character = from.parameter_character.to_s.dup
        to.parameter_escape     = from.parameter_escape.to_s.dup
      end

      def context_attr_reader(*names)
        names.each do |name|
          define_method name do
            current_context.send(name)
          end
        end
      end

      def context_attr_writer(*names)
        names.each do |name|
          define_method "#{name}="  do |value|
            current_context.send("#{name}=", value)
          end
        end
      end

      def context_attr_accessor(*names)
        context_attr_reader(*names)
        context_attr_writer(*names)
      end
    end
  end
end
