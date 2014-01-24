#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Classes to define checks on strings

require 'lib/string'
require 'lib/bun/file/descriptor'

# TODO Actually, Examinations no longer necessarily have anything to do with Strings
class String
  class Trait
    class Invalid < ArgumentError; end

    USAGE_FILE = ::File.join(Bun.project_path(__FILE__), Bun.project_relative_path('doc/exam_usage.md'))
    
    class << self
      def trait_class(analysis)
        class_name = analysis.to_s.gsub('_',' ').titleize.gsub(/\s+/,'')
        raise Invalid, "Bad analysis: #{analysis.inspect}" if class_name == ''
        const_defined?(class_name) ? const_get(class_name) : nil
      end
      
      def create(analysis, options={})
        klass = trait_class(analysis)
        raise Invalid, "Trait class not defined: #{analysis}" unless klass
        raise Invalid, "Trait class is not a String::Trait: #{analysis}" \
            unless klass < String::Trait::Base
        klass.new(options)
      end
      
      def trait(string, analysis)
        trait = create(analysis)
        trait.attach(:string, string)
        trait
      end
      
      def examine(string, analysis)
        trait(string, analysis).value
      end
      
      def trait_directory
        ::File.join(Bun.project_path(__FILE__),Bun.project_relative_path(__FILE__.sub(/\.rb$/,'')))
      end
      
      def all_trait_files
        Dir[::File.join(trait_directory,"*.rb")] \
          .map{|f| f.sub(%r{^#{trait_directory}/},'')}
      end
      
      def traits
        all_trait_files.select{|f| f =~ /_trait\.rb$/ }.map{|f| f.sub(/_trait.rb$/,'')}
      end
      
      def trait_definitions
        traits.map do |trait|
          klass = trait_class(trait)
          [trait, klass && klass.send(:description)]
        end
      end
      
      def trait_definition_table
        ([%w{Analysis Definition}] + trait_definitions) \
          .justify_rows \
          .map{|row| row.join('  ')} \
          .join("\n")
      end

      def usage
        begin
          text = ::File.read(USAGE_FILE)
          eval(text.inspect.gsub('\\#{','#{'))
        rescue => e
          warn "Error: #{e}"
          text
        end
      end
    end
  end
end

String::Trait.all_trait_files.each do |f|
  # TODO Fix this -- it only works in the home directory
  require "lib/trait/#{f.sub(/\.rb$/,'')}"
end
