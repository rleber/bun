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
          :tape_size,
          :tape_type,
          :tape,
          # :tape_path,
          # :original_tape,
          # :original_tape_path,
          :owner,
          :path,
          :digest,
          # :specification,
          # :updated,
        ]
      
        attr_reader :data, :fields
      
        def initialize(data)
          reset_fields
          set_field('data', data)
        end
        
        def reset_fields
          @fields = []
          register_fields(FIELDS)
        end
      
        def register_fields(*fields)
          fields.flatten.each {|field| register_field(field) }
        end
      
        def register_field(field)
          set_field(field, nil) unless @fields.include?(field)
        end
        
        def set_field(name, value)
          name = name.to_sym
          return if name==:digest
          _set_field name, value
          set_digest if name == :data
        end
        
        def _set_field(name, value)
          @fields << name unless @fields.include?(name)
          instance_variable_set("@#{name}", value)
        end
        private :_set_field
        
        def set_digest
          _set_field :digest, @data && @data.data.digest
        end
      
        def to_hash
          fields.inject({}) do |hsh, f|
            hsh[f] = self.send(f)
            hsh
          end
        end
      
        def from_hash(h)
          reset_fields
          merge!(h)
        end
        
        def merge!(h)
          h.keys.each do |k|
            set_field(k, h[k])
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
            instance_variable_get("@#{meth}")
          else
            data.respond_to?(meth) ? data.send(meth, *args, &blk) : nil
          end
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