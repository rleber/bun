#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

require 'indexable_basic'

module Slicr
  module Slice
    class Accessor
      include Indexable::Basic
      
      attr_reader :definition
      attr_reader :parent

      def initialize(definition, parent)
        @definition = definition
        @parent = parent
        self.index_array_class = Slice::Array
      end
      
      # Allows you to say things like stuff.byte.count, stuff.integer.hex, or stuff.integer.unsigned
      def method_missing(name, *args, &blk)
        return @res if _try(@definition, name, *args, &blk)
        raise NoMethodError, "#{@definition.name}##{name} not permitted for multiple values" if size > 1
        raise NoMethodError, "#{@definition.name}##{name} not permitted for empty collection" if size == 0
        raise NoMethodEror,  "#{@definition.name}##{name} not permitted for non-collapsing slices" unless @definition.collapse?
        value = self.at(0)
        raise NoMethodError, "#{@definition.name}##{name} method not defined" unless _try(value, name, *args, &blk)
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
      
      def to_a
        self[0..-1]
      end
      
      alias_method :old_index, :[]
      
      def [](*args)
        condensed_values self.old_index(*args)
      end
      
      def at(index)
        conform(parent.get_slice(index, definition.width, definition.offset) & definition.mask)
      end
      
      def conform(value)
        case value
        when definition.slice_class
          value
        when Fixnum
          definition.slice_class.new(value)
        else
          raise "Conversion! #{value.class} => #{definition.slice_class}"
          definition.slice_class.new(value.internal_value)
        end
      end
      
      def condensed_values(values)
        if values.nil?
          nil
        elsif values.is_a?(::Array)
          Slice::Array.new(values)
        else
          conform(values)
        end
      end
      
      def size
        # TODO May not need this OR
        definition.count || definition.parent_class.slice_count(definition)
      end
    end
  end
end