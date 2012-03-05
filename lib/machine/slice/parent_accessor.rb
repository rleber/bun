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
      
      # Allows you to say things like stuff.byte.count, stuff.integer.hex, or stuff.integer.unsigned
      def method_missing(name, *args, &blk)
        success = false
        res = nil
        begin
          res = @definition.send(name, *args, &blk)
          success = true
        rescue NoMethodError
        end
        unless success
          values = self[0..-1]
          if values.is_a?(::Array)
            raise NoMethodError, "#{@definition.name}##{name} not permitted: #{definition.name} has multiple values"
          else
            begin
              res = values.send(name, *args, &blk)
            rescue NoMethodError
              raise NoMethodError, "#{@definition.name}##{name} method not defined"
            end
          end
        end
        res
      end
    end
  end
end