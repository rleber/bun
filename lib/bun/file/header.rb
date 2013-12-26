#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# TODO Get rid of me
module Bun
  class File < ::File
    class Header < Bun::File::Raw
      HEADER_SIZE = Descriptor::Converted.maximum_size
      
      # TODO Should read in two gulps: first to get the descriptor + one freeze file descriptor (if there), then get descriptors
      def size(options={})
        HEADER_SIZE
      end
      
      def initialize(options={}, &blk)
        stop "!Building File::Header"
        file = options[:file]
        data = options[:data]
        words = options[:words]
        words = if file
          @file = file
          words = self.class.decode(self.class.read(file, size))
        elsif data
          @tape = options[:tape]
          words = self.class.decode(data[0...size])
        else
          @tape = options[:tape]
          words = words[0...size.div(characters_per_word)]
        end
        super(:words=>words, :size=>options[:size], :tape=>@tape, &blk)
      end
    end
  end
end