#!/usr/bin/env ruby
#  -*- encoding: utf-8 -*-

require 'lib/examination/wrapper'

module Bun
  class Expression
    class EvaluationError < RuntimeError; end

    class << self
      def wrap(value)
        case value
        when String::Examination::Base, String::Examination::FieldWrapper
          value
        else
          String::Examination::Wrapper.new(value)
        end
      end
    end
    
    class Context
      # Context for invocation of expressions in bun examine.
      # Should allow expressions to reference the following fields:
      #   file_path
      #   f[name], or simply name
      #   e[name], or simply name
      def initialize(file, path, data)
        @file = file
        @file_path = path
        @data = data
      end
    
      attr_reader :file_path
    
      def f
        @f ||= FieldAccessor.new(@file)
      end
    
      def e
        @e ||= ExamAccessor.new(@file, @data)
      end

      def text
        @data
      end
    
      def method_missing(name, *args, &blk)
        raise NoMethodError, "Method #{name} not defined" if args.size>0 || block_given?
        if f.has_field?(name)
          f[name]
        elsif e.has_exam?(name)
          e[name]
        else
          raise NoMethodError, "Method #{name} not defined"
        end
      end

     class FieldAccessor
        def initialize(file)
          @file = file
        end

        def has_field?(name)
          @file.descriptor.fields.include?(name.to_s)
        end
      
        def [](field_name)
          String::Examination::FieldWrapper.new(field_name, @file.descriptor[field_name.to_sym])
        end
      end
    
      class ExamAccessor
        def initialize(file, data)
          @file = file
          @data = data
          @bound_examinations = {}
        end
      
        def at(analysis)
          analysis = analysis.to_sym
          @bound_examinations[analysis] ||= @data.examination(analysis)
        end

        def has_exam?(name)
          String::Examination.exams.include?(name.to_s)
        end
      
        def [](analysis)
          at(analysis)
        end
      end
    end

    attr_accessor :data
    attr_reader   :expression
    
    def initialize(options={})
      @expression = options[:expression]
      @file = options[:file]
      @path = options[:path]
      @data = options[:data]
    end
    
    def value(options={})
      @context = Context.new(@file, @path, @data)
      value = begin
        @context.instance_eval(@expression)
      rescue => err
        if options[:raise]
          raise
        else
          raise EvaluationError, err.to_s
        end
      rescue SyntaxError => err # Blanket rescue doesn't trap syntax errors
        raise EvaluationError, err.to_s
      end
      self.class.wrap(value)
    end

    def code
      0
    end
    
    def to_s
      value.to_s
    end
  end
end
  
