#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

module Bun
  class File < ::File
    module Huffman
      class Word < ::Bun::File::Huffman::Base
        class << self
          def open_type
            :huffword
          end

          def data_type
            Bun::File::Huffman::Data::Word
          end
        end
      end
    end
  end
end
