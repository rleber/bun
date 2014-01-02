#!/usr/bin/env ruby
#  -*- encoding: utf-8 -*-

module Bun
  class Formula
    class Context
      # Context for invocation of formulas in bun examine.
      # Should allow expressions to reference the following fields:
      #   path
      #   fields[name]
      #   exams[name]
      def initialize(file, path, data)
        @file = file
        @path = @path
        @data = data
      end
    
      attr_reader :path
    
      def fields
        FieldAccessor.new(@file)
      end
    
      def exams
        ExamAccessor.new(@file, @data)
      end
    
      class FieldAccessor
        def initialize(file)
          @file = file
        end
      
        def [](field_name)
          @file.descriptor[field_name.to_sym]
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
      
        def [](analysis)
          at(analysis).to_s
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
    
    def to_s
      @context = Context.new(@file, @path, @data)
      @context.instance_eval(@expression)
    end
  end
end
  
