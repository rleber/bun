require 'machine/structure'

module Machine
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

    def get_slice(n, slice_width, offset=0, gap=0, width=nil)
      width ||= self.class.width
      super(n, slice_width, offset, gap, width)
    end
  end
end