module Machine
  module Slice
    class Base < GenericNumeric
      class << self
        def definition=(defn)
          @definition = defn
        end
        
        def definition
          @definition
        end
      
        def clip(value)
          all_ones & value
        end

        %w{size offset count significant_bits string? mask default_format}.each do |meth|
          define_method meth do
            definition.send(meth)
          end
        end
        
        attr_accessor :formats
      
        def sample_values
          [Machine::Word.all_ones(size), Machine::Word.all_ones(size-1)||0, 1<<(size-1), 0]
        end
      
        def add_formats(formats)
          formats.each do |name, format|
            add_format(name, format)
          end
        
          default = @formats[default_format]
          add_format :inspect, Format.new(:inspect, default.definition)
          @formats[:default] = Format.new(:default, default.definition)

          # TODO: Allow for unpadded formatting, and types which are unpadded by default
          # TODO: Base inspect formatting on Class statically-defined inspect method?
          def_method :format do |*args|
            format_defn = args[0] || :default
            format = @formats[format_defn] if format_defn.is_a?(Symbol)
            if format
              format_definition = format[:definition]
              v = format.string? ? self.string : self.value
              v = v.inspect if format.inspect?
            else
              format_definition = format_defn || word_default_format # TODO '%p' would be better, but would cause endless recursion currently
              v = self.value
            end
            format_definition % [v]
          end

          def_method :inspect do ||
            format.name(:inspect)
          end
        end

        def add_format(name, format)
          definition = format.adjusted_definition(self)
          raise RuntimeError, "Format #{format.name.inspect} is not supported for slice #{self.slice_name}." unless definition
          @formats ||= {}
          @formats[format.name] = format

          def_method format.name do ||
            format(format.name)
          end
        end
        
        # TODO Is this necessary?
        def slice_name
          definition.name
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
            single_bit_mask(sign_bit)
          end
          
          def sign(val)
            val & sign_mask
          end

          def complement(value)
            clip( ~value + 1)
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
        end
      end
    end
  
    class String < Base
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