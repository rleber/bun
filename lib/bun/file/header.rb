#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# TODO Get rid of me
module Bun
  class File < ::File
    class Header < Bun::File
      HEADER_SIZE = Descriptor.maximum_size
      
      # TODO Should read in two gulps: first to get the descriptor + one freeze file descriptor (if there), then get descriptors
      def size(options={})
        HEADER_SIZE
      end
      
      def initialize(options={}, &blk)
        file = options[:file]
        data = options[:data]
        words = options[:words]
        words = if file
          @file = file
          words = self.class.decode(self.class.read(file, size))
        elsif data
          @location = options[:location]
          words = self.class.decode(data[0...size])
        else
          @location = options[:location]
          words = words[0...size.div(characters_per_word)]
        end
        super(:words=>words, :size=>options[:size], :location=>@location, &blk)
      end
    end
  end
end