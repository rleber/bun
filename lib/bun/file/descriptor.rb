#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

module Bun
  class File < ::File
    module Descriptor
      class Base
        class << self
          def from_hash(data, h)
            d = new(data)
            d.from_hash(h)
          end
        end
        FIELDS = [
          # :basename,
          # :catalog_time,
          :description,
          # :errors,
          # :decoded,
          :file_size,
          :file_type,
          :tape,
          # :tape_path,
          # :original_tape,
          # :original_tape_path,
          :owner,
          :path,
          # :specification,
          # :updated,
        ]
      
        attr_reader :data, :fields
      
        def initialize(data)
          @data = data
          @fields = []
          # TODO fields should be registered in the class (and different file types should subclass File::Descriptor)
          register_fields(FIELDS)
        end
      
        def register_fields(*fields)
          fields.flatten.each {|field| register_field(field) }
        end
      
        def register_field(field)
          unless @fields.include?(field)
            instance_variable_set("@#{field}", nil)
            @fields << field
          end
        end
      
        def to_hash
          fields.inject({}) do |hsh, f|
            hsh[f] = self.send(f)
            hsh
          end
        end
      
        def from_hash(h)
          fields.each do |f|
            instance_variable_set("@#{f}", nil)
          end
          merge!(h)
        end
        
        def merge!(h)
          h.keys.each do |k|
            register_field(k) unless @fields.include?(k)
            instance_variable_set("@#{k}", h[k])
          end
          self
        end
        
        def dup
          h = to_hash
          n = self.class.new(self.data)
          n.from_hash(h)
          n
        end
        
        def merge(h)
          dup.merge!(h)
        end
        
        def [](arg)
          self.send(arg)
        end
        
        # Like to_hash, but omits content
        def precis
          hash = to_hash
          hash.delete(:content)
          hash
        end
        
        def timestamp
          fields.include?(:catalog_time) ? [file_time, catalog_time].compact.min : file_time
        end
      
        # def shards
        #   data.shard_descriptor_hashes rescue []
        # end
          
        def method_missing(meth, *args, &blk)
          if !block_given? && args.size==0 && instance_variable_defined?("@#{meth}")
            return instance_variable_get("@#{meth}")
          end
          data.respond_to?(meth) ? data.send(meth, *args, &blk) : nil
        end
      
        def copy(to, new_settings={})
          to_dir = File.dirname(to)
          descriptor = self.to_hash
          # descriptor[:original_tape] = descriptor[:tape] unless descriptor[:original_tape]
          # descriptor[:original_tape_path] = descriptor[:tape_path] unless descriptor[:original_tape_path]
          # descriptor[:tape] = File.basename(to)
          # descriptor[:tape_path] = to
          descriptor.merge! new_settings
          descriptor
        end
      end
    end
  end
end