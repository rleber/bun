require 'indexable_basic'

module Machine
  module Slice
    class Accessor
      
      attr_reader :definition
      attr_reader :parent

      def initialize(definition, parent)
        @definition = definition
        @parent = parent
      end
      
      # Allows you to say things like stuff.byte.count, stuff.integer.hex, or stuff.integer.unsigned
      def method_missing(name, *args, &blk)
        return @res if _try(@definition, name, *args, &blk)
        values = self[0..-1]
        raise NoMethodError, "#{@definition.name}##{name} not permitted for multiple values" if values.is_a?(::Array)
        raise NoMethodError, "#{@definition.name}##{name} method not defined" unless _try(values, name, *args, &blk)
        @res
      end
      
      def _try(object, name, *args, &blk)
        begin
          @res = object.send(name, *args, &blk)
          return true
        rescue NoMethodError
          return false
        end
      end
    end
    
    class SliceAccessor < Accessor
      
      attr_accessor :collapse

      def initialize(definition, parent)
        super
        @slicer = Slicer.new(definition, parent)
        @collapse = definition.collapse?
      end
      
      def collapse?
        @collapse
      end
      
      # TODO Create a collapsed do ... end idiom?
      def array
        # puts "In #{definition.name} slicer: count=#{}"
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
        if values.nil?
          nil
        elsif !values.is_a?(::Array)
          definition.slice_class.new(values)
        elsif values.size == 1 && collapse?
          definition.slice_class.new(values.first)
        else
          Slice::Array.new(values.map{|v| definition.slice_class.new(v)})
        end
      end
      
    end
    
    class Slicer
      include Indexable::Basic
      
      attr_reader :definition, :parent
      
      def initialize(definition, parent)
        @definition = definition
        @parent = parent
      end
      
      def at(i)
        definition.retrieve(parent, i)
      end
      
      def size
        # TODO May not need this OR
        definition.count || definition.parent_class.slice_count(definition)
      end
    end
  end
end