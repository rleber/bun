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
      
      attr_accessor :altered
      
      def initialize(options={})
        @data = Data.new(:archive=>options[:archive], :data=>options[:data], :tape=>options[:tape], :tape_path=>options[:tape_path])
        super
      end

      def data
        @data.reload if @altered
        @altered = false
        @data
      end
     
      # Convert file from internal Bun binary format to YAML digest
      def to_unpacked_file
        new_descriptor = data.descriptor.merge( :tape_type=>data.tape_type )
        tp = File.expand_path(data.tape_path)
        block_padding_repaired_data = Bun.cache(:repaired_data, tp) do
          data.with_block_padding_repaired
        end
        new_descriptor.merge!(
          block_padding_repairs: block_padding_repaired_data.block_padding_repairs,
          block_count:           block_padding_repaired_data.block_count,
          first_block_size:      block_padding_repaired_data.first_block_size,
        )

        f = File::Unpacked.create(
          :data=>block_padding_repaired_data,
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