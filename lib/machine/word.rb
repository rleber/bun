require 'machine/structure'

module Machine
  class Word < Structure
    
    class << self
      def fixed_size?
        true
      end
      
      def size(n=nil)
        if n.nil?
          @size
        else
          @size=n
        end
      end
      
      def ones_mask(n=size)
        super(n)
      end
      
      def define_size(word_size)
        @size = word_size
      end
      
      def slice(slice_name, options={}, &blk)
        slice_definition = super(slice_name, options, &blk)
        # slice_definition.count = slice_count(slice_definition)
        slice_definition
      end
      
      def slice_count(slice, options={})
        options = options.dup
        options[:data_size] ||= size
        super(slice, options)
      end
    end

    def get_slice(n, size, offset=0, gap=0, width=nil)
      width ||= self.class.size
      super(n, size, offset, gap, width)
    end
  end
end