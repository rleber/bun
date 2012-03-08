require 'slicr/structure'

module Slicr
  class Word < Structure
    
    class << self
      def fixed_width?
        true
      end
      
      def width(n=nil)
        if n.nil?
          @width
        else
          @width=n
        end
      end
      
      def ones_mask(n=width)
        super(n)
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

    def get_slice(n, options)
      slice_width = options[:width]
      offset = options[:offset] || 0
      gap = options[:gap] || 0
      width = self.class.width
      super(n, slice_width, offset, gap, width)
    end
    
    def width
      self.class.width
    end
  end
end