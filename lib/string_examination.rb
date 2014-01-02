#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Classes to define checks on strings

require 'lib/string'

class String
  class Examination
    class Invalid < ArgumentError; end
    
    class << self
      def exam_class(analysis)
        class_name = analysis.to_s.titleize
        raise Invalid, "Bad analysis: #{analysis.inspect}" if class_name == ''
        const_defined?(class_name) ? const_get(class_name) : nil
      end
      
      def create(analysis, string='')
        klass = exam_class(analysis)
        raise Invalid, "Examination class not defined: #{analysis}" \
            unless klass && klass < String::Examination::Base
        klass.new(string)
      end
      
      def examination(string, analysis)
        create(analysis, string).analysis
      end
      
      def exam_directory
        Bun.project_relative_path(__FILE__.sub(/\.rb$/,''))
      end
      
      def all_exam_files
        Dir[File.join(exam_directory,"*.rb")] \
          .map{|f| f.sub(%r{^#{exam_directory}/},'')}
      end
      
      def exams
        all_exam_files.select{|f| f =~ /_exam\.rb$/ }.map{|f| f.sub(/_exam.rb$/,'')}
      end
      
      def exam_definitions
        exams.map do |exam|
          klass = exam_class(exam)
          [exam, klass && klass.send(:description)]
        end
      end
      
      def exam_definition_table
        ([%w{Analysis Definition}] + exam_definitions) \
          .justify_rows \
          .map{|row| row.join('  ')} \
          .join("\n")
      end
    end
  end
end

require 'lib/string'
String::Examination.all_exam_files.each do |f|
  require "lib/string_examination/#{f.sub(/\.rb$/,'')}"
end
