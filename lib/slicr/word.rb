#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

require 'slicr/structure'

module Slicr
  class Word < Structure
    
    class << self
      def width(n=nil)
        if n
          @width=n
        else
          @width
        end
      end
      
      def get_width
        @width
      end
      
      def slice(slice_name, options={}, &blk)
        slice_definition = super(slice_name, options, &blk)
        # slice_definition.count = slice_count(slice_definition)
        slice_definition
      end
      
      def slice_count(slice, options={})
        options = options.dup
        options[:data_size] ||= width
        super(slice, options)
      end
    end

    def get_slice(n, size, offset)
      super(n, size, offset, self.width)
    end
    
    def width
      self.class.get_width
    end
  end
end