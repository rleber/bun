#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

require 'date'

module Bun

  class File < ::File
    class Raw < Bun::File
      class << self
        def open(fname, options={}, &blk)
          path = expand_path(fname)
          data = read(path)
          obj = self.send(:new,options.merge(:data=>data, :tape=>fname, :tape_path=>path))
          if block_given?
            yield(obj)
          else
            obj
          end
        end
      end
      
      attr_reader :data
      
      def initialize(options={})
        @data = Data.new(:archive=>options[:archive], :data=>options[:data], :tape=>options[:tape], :tape_path=>options[:tape_path])
        super
      end
     
      # Convert file from internal Bun binary format to YAML digest
      def convert
        @data.descriptor.to_hash.merge(:format=>:raw,:content=>data.data).to_yaml
      end

      def method_missing(meth, *args, &blk)
        @data.descriptor.send(meth, *args, &blk)
      rescue NoMethodError => e
        raise NoMethodError, %{"#{self.class}##{meth} method not defined:\n  Raised #{e} at:\n#{e.backtrace.map{|c| '    ' + c}.join("\n")}}
      end
    end
  end
end