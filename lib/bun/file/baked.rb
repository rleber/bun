#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

module Bun

  class File < ::File
    class Baked < ::File
      class << self
        def roff(from, to, options={})
          Roff.process_file(from, to, options)
        end
      end

      def descriptor
        @descriptor ||= File::Descriptor::Base.from_hash(nil, format: :baked)
      end

      # TODO DRY this up; see File::Decoded, for instance
      def decode(to, options={}, &blk)
        to = yield(self, 0) if block_given? # Block overrides "to"
        shell = Shell.new
        shell.mkdir_p(File.dirname(to)) unless to.nil? || to == '-'
        shell.write(to, read) unless to.nil?
      end

      def bake(to, options={})
        shell = Shell.new
        shell.mkdir_p(File.dirname(to)) unless to.nil? || to == '-'
        text = read
        text = text.scrub if options[:scrub]
        shell.write(to, text) unless to.nil?
      end

      def scrub(to)
        bake(to, :scrub=>true)
      end
    end
  end
end