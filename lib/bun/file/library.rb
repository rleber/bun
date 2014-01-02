#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

require 'date'

module Bun

  class File < ::File
    class Library < Bun::File
      attr_accessor :descriptor
      attr_accessor :library
      
      def initialize(options={}, &blk)
        @library = options[:library]
        @descriptor = options[:descriptor]
        @descriptor ||= @library.descriptor(options[:tape_path]) if @library && options[:tape_path]
        super(options.merge(:archive=>@library), &blk)
      end
  
      def content
        read
      end
    end
  end
end