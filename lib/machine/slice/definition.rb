require 'machine/slice/dsl'

module Machine
  module Slice
    class Definition

      attr_accessor :bits
      attr_accessor :count
      attr_accessor :class_name
      attr_accessor :slice_class
      attr_accessor :slice_class
      attr_accessor :default_format
      attr_accessor :formats
      attr_accessor :gap
      attr_accessor :mask
      attr_accessor :name
      attr_accessor :offset
      attr_accessor :options
      attr_accessor :parent_class
      attr_accessor :plural
      attr_accessor :sign
      attr_accessor :width
      
      class << self
        @@definitions = []
        
        def register(slice)
          @@definitions << slice
        end
      end

      VALID_SIGNS = [:none, :ones_complement, :twos_complement]
    
      def initialize(slice_name, parent_class, opts={}, &blk)
        @name = slice_name.to_s.downcase
        @plural = @name.pluralize
        @class_name = @name.gsub(/(^|_)(.)/) {|match| $2.upcase}
        @parent_class = parent_class
        self.class.register(self)

        self.options = {}
        Slice::DSL.new(self, &blk) if block_given? # Processes Slice definition DSL; sets self.options
        self.options.merge!(opts)

        @is_string = !!options[:string]
        @sign = options[:sign] || :none
        @slice_class = make_class
        @width = options[:width]
        @offset = options[:offset] || 0
        @bits = options[:bits] || @width
        @mask = options[:mask] || @parent_class.ones_mask(@bits)
        @default_format = options[:default_format]
        @formats = options[:format] || {}
        @gap = options[:gap] || 0
        @count = options[:count] || parent_class.slice_count(@width, :offset=>@offset, :gap=>@gap)
        @collapse = options[:collapse]
      end
      
      def install_formats
        @slice_class.install_formats(:formats=>@formats, :default=>@default_format)
      end
    
      def string?
        @is_string
      end
      
      def collapse?
        @collapse
      end
      
      def formats
        @slice_class.formats
      end
      
      def format_names
        @slice_class.format_names
      end
      
      def significant_bits
        @bits
      end
    
      def base_data_class
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
        slice_class = Class.new(base_data_class)
        parent_class.const_set(class_name, slice_class)
        slice_class.definition = self
        slice_class
      end
      
      def single_bit_mask(n)
        Machine::Word.single_bit_mask(n)
      end
      
      def retrieve(from_object, index)
        puts "#{slice_class} retrieve(#{from_object.class}, #{index.inspect}): width=#{width.inspect}, offset=#{offset.inspect}, gap=#{gap.inspect}"
        value = from_object.get_slice(index, width, offset, gap) & mask
        slice_class.new(value)
      end
    end
  end
end
