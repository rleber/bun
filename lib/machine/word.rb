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
      
      # TODO Should this be in Structure?
      def slice_count(slice, offset=0, gap=0)
        case slice
        when Numeric
          return nil unless size
          slice_size = slice
          available_bits = size - offset
          bits_per_slice = [slice_size+gap, available_bits].min
          available_bits.div(bits_per_slice)
        when Slice::Definition
          if slice.count
            slice.count
          else
            slice_count(slice.size, slice.offset, slice.gap)
          end
        else # Assume it's a name
          defn = slice_definition(slice)
          defn && slice_count(defn)
        end
      end
    end

    def get_slice(n, size, offset=0, gap=0, width=nil)
      width ||= self.class.size
      super(n, size, offset, gap, width)
    end
  end
end