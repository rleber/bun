# Create a DSL for defining slices

# TODO Reorganize slice* source files

module Slicr
  module Slice
    class DSL
      attr_reader :definition, :options
      
      def initialize(definition, &dsl_code)
        @definition = definition
        @options = {}
        if dsl_code.arity == 1      # the arity() check
          dsl_code[self]            # argument expected, pass the object
        else
          instance_eval(&dsl_code)  # no argument, use instance_eval()
        end
      end
      
      %w{width offset gap count bits string sign collapse}.each do |meth|
        meth = meth.to_sym
        define_method meth do |value|
          definition.options ||= {}
          definition.options[meth] = value
        end
      end
      
      %w{string collapse cached}.each do |boolean|
        boolean = boolean.to_sym
        define_method "#{boolean}?" do ||
          definition.options[boolean]
        end
        define_method boolean do |*args|
          value = args.size==0 ? true : args.first
          definition.options[boolean] = value
        end
      end
      
      def format(name, format)
        format = definition.options[:format][format] if format.is_a?(Symbol)
        definition.options[:format] ||= {}
        definition.options[:format][name.to_sym] = format
      end
    end
  end
end