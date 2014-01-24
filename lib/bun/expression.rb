#!/usr/bin/env ruby
#  -*- encoding: utf-8 -*-

require 'lib/examination/wrapper'

module Bun
  class Expression
    class EvaluationError < RuntimeError; end
    class EvaluationExpressionError < EvaluationError; end
    class EvaluationSyntaxError < EvaluationError; end
    class EvaluationParameterError < EvaluationError; end

    class Context
      # Context for invocation of expressions in bun examine.
      # Should allow expressions to reference the following fields:
      #   file_path
      #   f[name], or simply name
      #   e[name], or simply name

      attr_reader :expr

      def initialize(expr)
        @expr = expr
      end
    
      def f
        @f ||= FieldAccessor.new(self)
      end
    
      def e
        @e ||= ExamAccessor.new(self)
      end

      def text
        @expr.data
      end

      def file_object
        @expr.file
      end

      def file
        File.expand_path(@expr.path)
      end

      def wrap(value)
        value
      end

      # def fields
      #   wrap(@file.descriptor.fields)
      # end
    
      def method_missing(name, *args, &blk)
        if f.has_field?(name)
          raise NoMethodError, "Method #{name} not defined" if args.size>0 || block_given?
          f[name]
        elsif File::Descriptor::Base.field_valid?(name) # This is a valid field name, but this file hasn't got one
          FieldAccessor.wrap(name, File::Descriptor::Base.default_value_for(name))
        elsif e.has_exam?(name)
          raise NoMethodError, "Method #{name} not defined" if args.size>1 || block_given?
          options = args[0] || {}
          exam = e[name]
          options = {options=>true} if options.is_a?(Symbol)
          options.each do |key, value|
            begin
              exam.send("#{key}=", value)
            rescue NoMethodError
              raise EvaluationParameterError, "Examination #{name.inspect} does not recognize parameter #{key.inspect}"
            end
          end
          exam
        else
          raise NoMethodError, "Method #{name} not defined"
        end
      end

     class FieldAccessor
        attr_reader :context

        class << self
          def wrap(field_name, value)
            # String::Examination::FieldWrapper.new(field_name, value)
            value
          end
        end

        def initialize(context)
          @context = context
        end

        # TODO DRY this out
        def file_object
          context.file_object
        end

        def has_field?(name)
          file_object.descriptor.fields.map{|f| f.to_sym}.include?(name.to_sym)
        end
      
        def [](field_name)
          self.class.wrap(field_name, file_object.descriptor[field_name.to_sym])
        end
      end
    
      class ExamAccessor
        attr_reader :context

        def initialize(context)
          @context = context
          @bound_examinations = {}
        end
      
        def at(analysis, options={})
          analysis = analysis.to_sym
          unless @bound_examinations[analysis]
            examiner = String::Examination.create(analysis, options)
            context.expr.copy_attachment(:file, examiner)
            context.expr.copy_attachment(:data, examiner, :string)
            @bound_examinations[analysis] = examiner
          end
          @bound_examinations[analysis]
        end

        def has_exam?(name)
          String::Examination.exams.include?(name.to_s)
        end
      
        def [](analysis, options={})
          at(analysis, options)
        end
      end
    end

    attr_reader   :expression, :path
    
    def initialize(options={})
      @expression = options[:expression]
      @path = options[:path]
      @attachments = {}
    end
    
    def value(options={})
      @context = Context.new(self)
      value = begin
        @context.instance_eval(@expression)
      rescue => err
        if options[:raise]
          raise
        else
          raise EvaluationError, err.to_s
        end
      rescue SyntaxError => err # Blanket rescue doesn't trap syntax errors
        raise EvaluationSyntaxError, err.to_s
      end
      unless value.respond_to?(:to_matrix)
        titles = [ @expression =~ /^\w+$/ ? @expression.titleize : @expression ]
        value = String::Examination::Wrapper.wrap(value, :titles=>titles)
      end
      value
    end

    def code
      0
    end
    
    def to_s
      value.to_s
    end

    # Could DRY this out (also appears in Examinations)
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

    def copy_attachment(name, to, to_name=nil)
      name = name.to_sym
      to_name ||= name
      attachment = @attachments[name]
      if attachment.is_a?(Proc)
        to.attach(to_name, &attachment)
      else
        to.attach(to_name, attachment)
      end
      attachment
    end

    def file
      @file ||= retrieve(:file)
    end

    def data
      @data ||= retrieve(:data)
    end
  end
end
  
