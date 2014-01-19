#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Classes to define checks on strings

require 'lib/string'
require 'lib/bun/file/descriptor'

class String
  class Examination
    class Invalid < ArgumentError; end

    USAGE_FILE = File.join(Bun.project_path(__FILE__), Bun.project_relative_path('doc/exam_usage.md'))
    
    class << self
      def exam_class(analysis)
        class_name = analysis.to_s.gsub('_',' ').titleize.gsub(/\s+/,'')
        raise Invalid, "Bad analysis: #{analysis.inspect}" if class_name == ''
        const_defined?(class_name) ? const_get(class_name) : nil
      end
      
      def create(analysis, options={})
        klass = exam_class(analysis)
        raise Invalid, "Examination class not defined: #{analysis}" unless klass
        raise Invalid, "Examination class is not a String::Examination: #{analysis}" \
            unless klass < String::Examination::Base
        klass.new(options)
      end
      
      def examination(string, analysis)
        create(analysis, string)
      end
      
      def examine(string, analysis)
        examination(string, analysis).value
      end
      
      def exam_directory
        File.join(Bun.project_path(__FILE__),Bun.project_relative_path(__FILE__.sub(/\.rb$/,'')))
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

      def usage
        begin
          text = File.read(USAGE_FILE)
          eval(text.inspect.gsub('\\#{','#{'))
        rescue => e
          warn "Error: #{e}"
          text
        end
      end
    end
  end
end

String::Examination.all_exam_files.each do |f|
  # TODO Fix this -- it only works in the home directory
  require "lib/examination/#{f.sub(/\.rb$/,'')}"
end
