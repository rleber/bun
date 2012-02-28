module Machine
  module Slice
    class Definition
      attr_reader :bits
      attr_reader :class_name
      attr_reader :count
      attr_reader :data_class
      attr_reader :default_format
      attr_reader :formats
      attr_reader :gap
      attr_reader :mask
      attr_reader :name
      attr_reader :offset
      attr_reader :parent_class
      attr_reader :plural
      attr_reader :sign
      attr_reader :size
      
      class << self
        @@definitions = []
        
        def register(slice)
          @@definitions << slice
        end
      end

      VALID_SIGNS = [:none, :ones_complement, :twos_complement]
    
      def initialize(slice_name, parent_class, options={})
        @name = slice_name.to_s.downcase
        @plural = @name.pluralize
        @class_name = @name.gsub(/(^|_)(.)/) {|match| $2.upcase}
        @parent_class = parent_class
        @size = options[:size]
        @offset = options[:offset] || 0
        @bits = options[:bits] || @size
        @mask = options[:mask] || @parent_class.all_ones(@bits)
        @is_string = !!options[:string]
        @sign = options[:sign] || :none
        @default_format = options[:default_format] || (@is_string ? :string_inspect : (@sign == :none ? :octal : :decimal))
        @formats = options[:format] || {}
        @gap = options[:gap] || 0
        @count = options[:count]
        parent_data_class = data_class
        @data_class = make_class
        self.class.register(self)
      end
      
      def add_formats(formats)
        @data_class.add_formats(formats)
      end
    
      def string?
        @is_string
      end
      
      def significant_bits
        @bits
      end
    
      def data_class
        if string?
          Slice::String
        else
          case sign
          when :none then Slice::Unsigned
          when :ones_complement then Slice::Signed::OnesComplement
          when :twos_complement then Slice::Signed::TwosComplement
          else  
            raise ArgumentError, "Bad value for :sign (#{slice.sign.inspect}) of slice #{@name}. Should be one of #{VALID_SIGNS.inspect}"
          end
        end
      end
      
      def make_class
        slice_class = Class.new(data_class)
        parent_class.const_set(class_name, slice_class)
        slice_class.definition = self
        slice_class
      end
      
      def start_bit(n)
        @start_bit ||= []
        @start_bit[n] ||= _start_bit[n]
        start_bit[n]
      end
      
      def _start_bit(n)
        parent_class.slice_start_bit(n, size, offset, gap)
      end
      private :_start_bit
      
      def end_bit(n)
        @end_bit ||= []
        @end_bit[n] ||= _end_bit[n]
        end_bit[n]
      end
      
      def _end_bit(n)
        parent_class.slice_end_bit(n, size, offset, gap)
      end
      private :_end_bit
      
      def shift(n)
        @shift ||= []
        @shift[n] ||= _shift[n]
        shift[n]
      end
      
      def _shift(n)
        parent_class.slice_shift(n, size, offset, gap)
      end
      private :_shift
      
      def mask(n)
        @mask ||= []
        @mask[n] ||= _mask[n]
        mask[n]
      end
      
      def _mask(n)
        mask = parent_class.slice_mask(n, size, offset, gap)
        clip_to = (slice.mask << shift(n))
        mask & clip_to
      end
      private :_mask
      
    end
  end
end
