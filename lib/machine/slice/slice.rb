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

        %w{width offset count significant_bits string? mask}.each do |meth|
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
      class Base < Slice::Numeric

        attr_reader :ignore_sign

        class << self 
          def sign_bit
            0
          end
          
          def sign_mask
            single_bit_mask(width-sign_bit-1)
          end
          
          def sign(val)
            val & sign_mask
          end
        end
        
        def initialize(val, options={})
          warn "In Signed::Base.new(#{val.inspect} (class #{val.class}), #{options.inspect})"
          if val<0
            val = self.class.complement(-val)
          end
          super(val)
          @ignore_sign = options[:ignore_sign]
        end

        def value
          _signed
        end
    
        def sign
          (@ignore_sign ? 0 : self.class.sign(internal_value)) >> (self.class.width-self.class.sign_bit-1)
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
      
      class TwosComplement < Slice::Signed::Base
        class << self
          def complement(value)
            clip( ~value + 1)
          end
          
          def sign_type
            :twos_complement
          end
        end
        
        def initialize(val, options={})
          warn "In TwosComplement.new(#{val.inspect} (class #{val.class}), #{options.inspect})"
          super
        end
      end
      
      class OnesComplement < Slice::Signed::Base
        class << self 
          def complement(value)
            # warn "complement(#{'%012o' % value}) => #{'%012o' % (~value)}, clipped = #{'%012o' % clip(~value)}"
            clip( ~value )
          end
          
          def sign_type
            :ones_complement
          end
        end
        
        def initialize(value, options={})
          warn "In OnesComplement.new(#{value.inspect} (class #{value.class}), #{options.inspect})"
          warn %Q{caller:\n#{caller.map{|s| '  ' + s}.join("\n")}}
          super
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
        internal_value
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