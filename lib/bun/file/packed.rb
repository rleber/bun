#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

require 'date'

module Bun

  class File < ::File
    class Packed < Bun::File
      class << self
        def open(fname, options={}, &blk)
          if !options[:force] && (grade = File.file_grade(fname)) != :packed
            raise BadFileGrade, "#{fname} can't be converted to packed"
          else
            path = fname
            path = expand_path(fname) unless fname == '-'
            data = read(path)
            obj = self.send(:new,options.merge(:data=>data, :tape=>fname, :tape_path=>path))
            if block_given?
              yield(obj)
            else
              obj
            end
          end
        end
      end
      
      attr_reader :data
      
      def initialize(options={})
        @data = Data.new(:archive=>options[:archive], :data=>options[:data], :tape=>options[:tape], :tape_path=>options[:tape_path])
        super
      end
     
      # Convert file from internal Bun binary format to YAML digest
      def to_unpacked_file
        new_descriptor = data.descriptor.merge(
                              :data_format=>:raw, 
                              :tape_type=>data.tape_type,
                            )
        f = File::Unpacked.create(
          :data=>data,
          :archive=>archive,
          :tape=>File.basename(tape),
          :tape_path=>tape_path,
          :descriptor=>new_descriptor,
        )
        if data.tape_type == :frozen
          f.descriptor.merge!(:shards=>f.shard_descriptors)
        end
        f
      end

      def descriptor
        data.descriptor
      end
      
      # TODO Redefine this: unpack(to, options={})
      def unpack
        to_unpacked_file
      end

      def method_missing(meth, *args, &blk)
        @data.descriptor.send(meth, *args, &blk)
      rescue NoMethodError => e
        raise NoMethodError, %{"#{self.class}##{meth} method not defined:\n  Raised #{e} at:\n#{e.backtrace.map{|c| '    ' + c}.join("\n")}}
      end
    end
  end
end