#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

module Bun
  class File < ::File
    module Huffman
      class Base < ::Bun::File::Blocked
        class << self
          def open(path, options={}, &blk)
            File::Unpacked.open(path, options.merge(:type=>open_type), &blk)
          end
        end

        def initialize(options={})
          options[:data] = self.class.data_type.new(options) \
            if options[:data] && 
               (!options[:data].is_a?(self.class.data_type)) &&
               (!options[:data].is_a?(Bun::Data))
          super
        end

        def binary
          data.binary
        end

        def bcd
          data.bcd
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
end
