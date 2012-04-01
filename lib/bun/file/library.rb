#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

require 'date'

module Bun

  class File < ::File
    class Library < Bun::File
      class << self
        def open(fname, options={}, &blk)
          new(options.merge(:location_path=>fname), &blk)
        end
      end
      
      attr_accessor :descriptor
      attr_accessor :library
      
      def initialize(options={}, &blk)
        @library = options[:library]
        @descriptor = options[:descriptor]
        @descriptor ||= @library.descriptor(options[:location_path]) if @library && options[:location_path]
        super(options.merge(:archive=>@library), &blk)
      end
  
      def content
        read
      end
    end
  end
end