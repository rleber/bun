#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

module Bun

  class File < ::File
    class Baked < ::File
      def descriptor
        nil
      end

      def descriptor
        @descriptor ||= File::Descriptor::Base.from_hash(nil, file_grade: :baked)
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
        shell.write(to, read) unless to.nil?
      end
    end
  end
end