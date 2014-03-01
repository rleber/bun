#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

module Bun
  class File < ::File
    class Huffman < ::Bun::File::Blocked
      include CacheableMethods

      class << self
        def open(path, options={}, &blk)
          File::Unpacked.open(path, options.merge(:type=>:huffman), &blk)
        end
      end

      def initialize(options={})
        options[:data] = HuffmanData.new(options) if options[:data] && (!options[:data].is_a?(Bun::HuffmanData)
          !options[:data].is_a?(Bun::Data))
        super
      end

      def binary
        data.binary
      end

      def decoded_text(options={})
        data.text
      end

      def content_start
        data.content_start
      end
    end
  end
end
