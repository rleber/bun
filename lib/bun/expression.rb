#!/usr/bin/env ruby
#  -*- encoding: utf-8 -*-

require 'lib/trait/wrapper'

module Bun
  class Expression
    class EvaluationError < RuntimeError; end
    class EvaluationExpressionError < EvaluationError; end
    class EvaluationSyntaxError < EvaluationError; end
    class EvaluationParameterError < EvaluationError; end

    class Context
      # Context for invocation of expressions in bun traitine.
      # Should allow expressions to reference the following fields:
      #   file_path
      #   f[name], or simply name
      #   e[name], or simply name

      attr_reader :expr

      def initialize(expr)
        @expr = expr
      end
    
      def field
        @field ||= FieldAccessor.new(self)
      end
    
      def trait
        @trait ||= TraitAccessor.new(self)
      end

      def text
        @expr.data
      end

      def file_object
        @expr.file
      end

      def file
        f = File.expand_path(@expr.path)
        f += "[#{@expr.shard}]" if @expr.shard
        f
      end

      def earliest_time
        trait[:times].value[:earliest_time]
      end

      def format
        field[:format]
      end

      def wrap(value)
        value
      end

      # def fields
      #   wrap(@file.descriptor.fields)
      # end
    
      def method_missing(name, *args, &blk)
        if trait.has_trait?(name)
          raise NoMethodError, "Method #{name} not defined" if args.size>1 || block_given?
          options = args[0] || {}
          this_trait = trait[name]
          options = {options=>true} if options.is_a?(Symbol)
          options.each do |key, value|
            begin
              this_trait.send("#{key}=", value)
            rescue NoMethodError
              raise EvaluationParameterError, "Trait #{name.inspect} does not recognize parameter #{key.inspect}"
            end
          end
          this_trait
        elsif File::Descriptor::Base.field_valid?(name) || File::Descriptor::Base.valid_file_field?(name)
          raise NoMethodError, "Method #{name} not defined" if args.size>0 || block_given?
          field[name]
        else
          raise NoMethodError, "Method #{name} not defined"
        end
      end

     class FieldAccessor
        attr_reader :context

        class << self
          # TODO Get rid of this
          def wrap(field_name, value)
            # String::Trait::FieldWrapper.new(field_name, value)
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
          file_object.descriptor.fields.map{|f| f.to_sym}.include?(name.to_sym) || File::Descriptor::Base.file_fields[name.to_sym]
        end
      
        def [](field_name)
          value = if File::Descriptor::Base.file_fields[field_name.to_sym]
            file_object.send(field_name)
          elsif has_field?(field_name)
            file_object.descriptor[field_name.to_sym]
          else
            File::Descriptor::Base.field_default_for(field_name)
          end
          self.class.wrap(field_name, value)
        end
      end
    
      class TraitAccessor
        attr_reader :context

        def initialize(context)
          @context = context
          @bound_traits = {}
        end
      
        def at(analysis, options={})
          analysis = analysis.to_sym
          unless @bound_traits[analysis]
            examiner = String::Trait.create(analysis, options)
            context.expr.copy_attachment(:file, examiner)
            context.expr.copy_attachment(:data, examiner, :string)
            @bound_traits[analysis] = examiner
          end
          @bound_traits[analysis]
        end

        def has_trait?(name)
          String::Trait.traits.include?(name.to_s)
        end
      
        def [](analysis, options={})
          at(analysis, options)
        end
      end
    end

    attr_reader   :expression, :path, :shard
    
    def initialize(options={})
      @expression = options[:expression]
      @path = options[:path]
      @shard = options[:shard]
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
        value = String::Trait::Wrapper.wrap(value, :titles=>titles)
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
  
