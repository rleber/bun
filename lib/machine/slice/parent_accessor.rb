require 'indexable_basic'

module Machine
  module Slice
    class ParentAccessor
      
      attr_reader :definition
      attr_reader :parent

      def initialize(definition, parent)
        @definition = definition
        @parent = parent
      end
      
      # def count
      #   @parent.slice_count(@definition)
      # end
      
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
        meths = definition.format_names
        meths += [:signed, :unsigned] if definition.sign != :none
        meths
      end
    end
  end
end