require 'slicr/formats'

module Slicr
  module Slice
    class Base < GenericNumeric
      include Formatted
      
      class << self
        def definition=(defn)
          @definition = defn
        end
        
        def definition
          @definition
        end
        
        def mask
          definition.mask
        end
        
        def single_bit_mask(n)
          definition.single_bit_mask(n)
        end
      
        def clip(value)
          mask & value
        end

        %w{width offset count significant_bits string? mask}.each do |meth|
          define_method meth do
            definition.send(meth)
          end
        end
       end

      def initialize(*args)
        super
        self.class.install_formats unless formats
      end
      
      def definition
        self.class.definition
      end
      
      def name
        self.class.slice_name
      end
    end
    
    class Numeric < Slice::Base; end
    
    class Unsigned < Slice::Numeric; end

    module Signed
      class Base < Slice::Numeric

        attr_reader :ignore_sign

        class << self 
          def sign_bit
            0
          end
          
          def sign_mask
            single_bit_mask(width-sign_bit-1)
          end
          
          def encoded_sign(val)
            (val & sign_mask) >> (width-sign_bit-1)
          end

          def sign(val)
            val < 0 ? 1 : 0
          end
          
          def ones_complement(value)
            clip( ~value )
          end
          
          def twos_complement(value)
            clip (~value + 1)
          end
          
          def encode(value)
            value < 0 ? complement(value.abs) : value
          end
          
          def decode(value)
            encoded_sign(value)==0 ? value : -complement(value)
          end
        end
        
        def initialize(val, options={})
          if val>=0
            val = self.class.decode(val)
          end
          super(val)
          # @ignore_sign = options[:ignore_sign]
        end

        def sign
          self.class.sign(internal_value)
        end

        def ones_complement
          self.class.ones_complement(internal_value)
        end

        def twos_complement
          self.class.twos_complement(internal_value)
        end
      
        def signed
          self
        end

        def unsigned
          Unsigned.new(self.class.encode(internal_value))
        end
      end
      
      class TwosComplement < Slice::Signed::Base
        class << self
          def complement(value)
            twos_complement(value)
          end
          
          def sign_type
            :twos_complement
          end
        end
      end
      
      class OnesComplement < Slice::Signed::Base
        class << self 
          def complement(value)
            clip( ~value )
          end
          
          def sign_type
            :ones_complement
          end
        end
      end
    end
  
    class String < Base
      class << self
        def string?
          true
        end
      end
      
      def to_str
        internal_value.chr
      end
    
      def +(other)
        internal_value.chr + other
      end
      
      def plus(other)
        internal_value + other
      end
    
      def add(other)
        internal_value + other
      end
      
      def to_s
        to_str
      end
      
      def value
        to_str
      end
      
      def asc
        Unsigned.new(internal_value)
      end

      def <=>(other)
        case other
        when GenericNumeric
          self.asc <=> other.value
        when Numeric
          self.asc <=> other
        when ::String
          self.value <=> other
        when String
          self.value <=> other.value
        else
          raise TypeError, "Can't compare #{self.class} with #{other.class}"
        end
      end
    end
  
    class Array < ::Array
      def string
        self.map{|e| e.string}.join
      end
      
      def values
        self.map{|e| e.values}
      end
    end
  end

end