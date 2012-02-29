require 'machine/formats'

module Machine
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

        %w{size offset count significant_bits string? mask default_format}.each do |meth|
          define_method meth do
            definition.send(meth)
          end
        end
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
      class TwosComplement < Slice::Numeric
        
        class << self 
          def sign_bit
            0
          end
          
          def sign_mask
            single_bit_mask(size-sign_bit-1)
          end
          
          def sign(val)
            val & sign_mask
          end

          def complement(value)
            clip( ~value + 1)
          end
          
          def sign_type
            :twos_complement
          end
        end
    
        attr_reader :ignore_sign
        
        def initialize(val, options={})
          super(val)
          @ignore_sign = options[:ignore_sign]
        end
        
        def value
          _signed
        end
    
        def sign
          (@ignore_sign ? 0 : self.class.sign(internal_value)) >> (size-self.class.sign_bit-1)
        end

        def complement
          self.class.new(_complement, :ignore_sign=>@ignore_sign)
        end

        def _complement
          self.class.complement(internal_value)
        end
        private :_complement
      
        def signed
          self.class.new(_signed, :ignore_sign=>false)
        end
    
        def _signed
          sign==0 ? _unsigned : -_abs
        end
        private :_signed
        
        def unsigned
          self.class.new(_unsigned, :ignore_sign=>true)
        end
        
        def _unsigned
          internal_value
        end
        private :_unsigned
      
        def abs
          self.class.new(_abs, :ignore_sign=>@ignore_sign)
        end
        
        def _abs
          sign==0 ? _unsigned : _complement
        end
        private :_abs
      end
      
      class OnesComplement < TwosComplement
        class << self 
          def complement(value)
            clip( ~value)
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
    
      def add(other)
        internal_value + other
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