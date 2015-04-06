#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

module Bun
  class File < ::File
    module Huffman
      class Basic < ::Bun::File::Huffman::Base
        class << self
          def open_type
            :huffman
          end

          def data_type
            Bun::File::Huffman::Data::Basic
          end
        end
      end
    end
  end
end
