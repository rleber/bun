#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

require 'date'

module Bun

  class File < ::File
    class Executable < Bun::File::Unpacked

      # Executables don't decode; they just copy
      def decode(to, options={}, &blk)
        write to, format: :decoded
      end

      def executable
        true
      end
    end
  end
end
