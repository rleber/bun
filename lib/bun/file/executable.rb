#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

require 'date'

module Bun

  class File < ::File
    class Executable < Bun::File::Unpacked

      class << self
        def open(path, options={}, &blk)
          File::Unpacked.open(path, options.merge(:type=>:executable), &blk)
        end
      end

      def initialize(options={})
        options[:data] = Data.new(options) if options[:data] && !options[:data].is_a?(Bun::Data)
        super
      end

      # Executables don't decode; they just copy
      def decoded_text(options={})
        descriptor.data.data
      end

      def executable
        true
      end

      def binary
        true
      end

      def bcd
        false
      end
    end
  end
end
