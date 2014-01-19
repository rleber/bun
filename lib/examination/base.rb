#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Base class to define analyses or tests on strings

class String
  class Examination
    class Base
      class Result
        attr_accessor :exam
        attr_accessor :value
        
        def initialize(exam,value)
          @exam = exam
          @value = value
        end

        def to_s
          exam.format(value)
        end

        def to_matrix
          [[exam.format(value)]]
        end

        # TODO Some of this could be dried up with other Result classes with a Mixin
        def titles
          exam.titles rescue nil 
        end

        def to_titled_matrix
          [titles ? [titles] : []] + to_matrix
        end

        def right_justified_columns
          []
        end
        
        # Behave like a Float
        def method_missing(meth, *args, &blk)
          value.send(meth, *args, &blk)
        end
      end

      # attr_accessor :string
      attr_reader :code
      attr_accessor :options
      attr_reader :attachments

      def self.result_class
        Result
      end
      
      # Should be overridden in subclasses
      def self.description
      end
      
      # Default; may be overridden in subclasses
      def self.justification
        :left
      end
      
      def description
        self.class.description
      end
      
      def missing_method(meth)
        stop "!#{self.class} does not define #{meth} method"
      end
    
      def initialize(options={})
        @attachments = {}
        @code = 0
        @options = options
      end

      def attach(name, value=nil, &blk)
        if block_given?
          @attachments[name.to_sym] = blk
        else
          @attachments[name.to_sym] = value
        end
      end

      def retrieve(name)
        v = @attachments[name.to_sym]
        v = v.call if v.is_a?(Proc)
        v
      end

      def string
        @string ||= retrieve(:string)
      end

      def string=(s)
        attach :string, s
      end

      def file
        @file ||= retrieve(:file)
      end

      def file=(f)
        attach :file, f
      end

      # Subclasses should define analysis method
      def analysis
        missing_method :analysis
      end
      
      # This allows subclass hooks, e.g.
      #    def make_value(x)
      #      ResultClass.new(x)
      #    end
      def make_value(x)
        self.class.result_class.new(self, x) # So subclasses can override Result class
      end
      
      def value
        self.value = make_value(analysis) unless @value
        @value
      end
      
      def value=(x)
        @value=make_value(x)
      end
      
      def reset
        @value = nil
      end
      
      def recalculate
        reset
        value
      end
      
      def to_s
        value.to_s
      end

      def to_matrix
        value.to_matrix
      end

      def to_titled_matrix
        value.to_titled_matrix
      end
      
      def inspect
        value.inspect
      end

      # Default; may be overridden in subclasses
      def self.justification
        :left
      end
      
      def format(x)
        x.to_s
      end
      
      def to_i
        value.to_i
      end
      
      def to_f
        value.to_f
      end
      
      def to_s
        format(value)
      end

      def right_justified_columns
        value.right_justified_columns
      end

      def class_basename
        self.class.to_s.sub(/^.*::/,'')
      end

      # TODO Could default this to the base Class name of the subclass
      def titles
        [class_basename]
      end
    end
  end
end
