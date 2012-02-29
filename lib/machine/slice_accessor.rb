require 'indexable_basic'

module Machine
  module Slice
    class Accessor
      
      attr_reader :definition
      attr_reader :container
      attr_accessor :collapse

      def initialize(definition, container)
        @definition = definition
        @container = container
        @slicer = Slicer.new(definition, container)
        @collapse = definition.collapse?
      end
      
      def collapse?
        @collapse
      end
      
      def array
        saved_collapse = collapse?
        self.collapse = false
        res = self[0..-1]
        self.collapse = saved_collapse
        res
      end
      alias_method :s, :array # So you can say stuff.bit.s
      
      def string
        raise NoMethodError, "#{@definition.name}#string is not allowed for non-string slices" unless @definition.string?
        self[0..-1].string
      end
      
      def [](*args)
        condensed_values @slicer[*args]
      end
      
      def condensed_values(values)
        if !values.is_a?(::Array)
          definition.data_class.new(values)
        elsif values.size == 1 && collapse?
          definition.data_class.new(values.first)
        else
          Slice::Array.new(values.map{|v| definition.data_class.new(v)})
        end
      end
      
      # Allows you to say things like stuff.byte.count, stuff.integer.hex, or stuff.integer.unsigned
      # Should allow stuff.integer (without the index)
      def method_missing(name, *args, &blk)
        if allowed_methods.include?(name)
          values = self[0..-1]
          if values.is_a?(::Array)
            raise NoMethodError, ".#{name} not permitted: #{definition.name} has multiple values"
          else
            values.send(name)
          end
        else # Try delegating to the definition
          begin
            @definition.send(name, *args, &blk)
          rescue NoMethodError
            raise NoMethodError, "#{@definition.name}##{name} method not defined"
          end
        end
      end
      
      def allowed_methods
        meths = definition.format_types
        meths += [:signed, :unsigned] if definition.sign != :none
        meths
      end
    end
    
    class Slicer
      include Indexable::Basic
      
      attr_reader :definition, :container
      
      def initialize(definition, container)
        @definition = definition
        @container = container
      end
      
      def at(i)
        definition.retrieve(container, i)
      end
      
      def size
        definition.count
      end
    end
  end
end