#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

module Bun
  class File < ::File
    module Descriptor
      class Base
        class << self
          def from_hash(file, h)
            d = new(file)
            d.from_hash(h)
          end
        end
        FIELDS = [
          :basename,
          :catalog_time,
          :description,
          :errors,
          :extracted,
          :file_size,
          :file_type,
          :hoard,
          :hoard_path,
          :original_hoard,
          :original_hoard_path,
          :owner,
          :path,
          :specification,
          :updated,
        ]
      
        attr_reader :file, :fields
      
        def initialize(file)
          @file = file
          @fields = []
          # TODO fields should be registered in the class (and different file types should subclass File::Descriptor)
          register_fields(FIELDS)
        end
      
        def register_fields(*fields)
          fields.flatten.each {|field| register_field(field) }
        end
      
        def register_field(field)
          @fields << field
        end
      
        def to_hash
          fields.inject({}) {|hsh, f| hsh[f] = self.send(f); hsh }
        end
      
        def from_hash(h)
          fields.each do |f|
            instance_variable_set("@#{f}", nil)
          end
          if h
            h.keys.each do |k|
              instance_variable_set("@#{k}", h[k])
            end
          end
          self
        end
      
        def shards
          file.shard_descriptor_hashes rescue []
        end
  
        def method_missing(meth, *args, &blk)
          file.send(meth, *args, &blk)
        rescue NoMethodError => e
          raise NoMethodError, %{"#{self.class}##{meth} method not defined:\n  Raised #{e} at:\n#{e.backtrace.map{|c| '    ' + c}.join("\n")}}
        end
      
        def copy(to, new_settings={})
          to_dir = File.dirname(to)
          to_archive = Archive.new(:at=>to_dir)
          descriptor = self.to_hash
          descriptor[:original_hoard] = descriptor[:hoard] unless descriptor[:original_hoard]
          descriptor[:original_hoard_path] = descriptor[:hoard_path] unless descriptor[:original_hoard_path]
          descriptor[:hoard] = File.basename(to)
          descriptor[:hoard_path] = to
          descriptor.merge! new_settings
          to_archive.update_index(:descriptor=>descriptor)
        end
      end
    end
  end
end