#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

module Bun
  class File < ::File
    module Huffman
      class Plus < ::Bun::File::Huffman::Base
        class << self
          def open_type
            :huffman_plus
          end

          def data_type
            Bun::File::Huffman::Data::Plus
          end
        end
      end
    end
  end
end
