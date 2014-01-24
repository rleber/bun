#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

require 'lib/bun/file/descriptor_fields'

module Bun
  class File < ::File
    module Descriptor
      class Base
        undef_method :format
        class << self
          def from_hash(data, h)
            d = new(data)
            d.from_hash(h)
          end

          def valid_fields
            @valid_fields ||= field_definitions.keys.sort
          end

          def all_fields
            all_field_definitions.keys.sort
          end

          def field_valid?(name)
            VALID_FIELDS.keys.include?(name.to_sym)
          end

          def field_definitions
            VALID_FIELDS
          end

          def synthetic_field_definitions
            SYNTHETIC_FIELDS 
          end

          def all_field_definitions
            @all_field_definitions ||= field_definitions.merge(synthetic_field_definitions)
          end

          def field_definition_array
            field_definitions.to_a.map{|key, defn| [key, defn.is_a?(Hash) ? defn[:desc] : defn]}.sort
          end

          def field_defaults
            @field_defaults ||=
              all_field_definitions.to_a.select{|key, defn| defn.is_a?(Hash) && defn[:default]} \
                .inject({}) {|hsh, pair| key, defn = pair; hsh[key] = defn[:default]; hsh}
          end

          def field_default_for(name)
            field_defaults[name.to_sym]
          end

          def all_field_definition_array
            all_field_definitions.to_a.map{|key, defn| [key, defn.is_a?(Hash) ? defn[:desc] : defn]}.sort
          end

          def all_field_definition_table
            ([%w{Field Description}] + all_field_definition_array) \
              .justify_rows \
              .map{|row| row.join('  ')} \
              .join("\n")
        end

        end

        class InvalidField < ArgumentError; end

        FIELDS = [
          :description,
          :tape_size,
          :type,
          :tape,
          :owner,
          :path,
          :digest,
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
        
        def set_field(name, value, options={})
          name = name.to_sym
          _set_field name, value, options
          set_digest if name == :data # If the data changes, so should the digest
        end
        
        def _set_field(name, value, options={})
          if options[:user]
            name = "user_#{name}" unless name =~ /^user_/
          else
            raise InvalidField, "Bad field #{name.inspect}" unless name =~ /^user_/ || self.class.field_valid?(name)
          end
          @fields << name unless @fields.include?(name)
          value = Shards.new(value) if name.to_s == 'shards' && !value.nil?
          instance_variable_set("@#{name}", value)
        end
        private :_set_field

        def delete(field)
          field = field.to_sym
          return unless @fields.include?(field)
          remove_instance_variable("@#{field}")
          @fields.delete(field)
        end

        def set_digest
          return unless @data
          data = @data
          data = data.data if data.respond_to?(:data)
          return unless data && data.respond_to?(:digest)
          _set_field :digest, data.digest
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
          t1 = fields.include?(:catalog_time) ? [time, catalog_time].compact.min : time
          fields.include?(:shard_time) ? [shard_time, t1].compact.min : t1
        end
              
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
          descriptor.merge! new_settings
          descriptor
        end
      end
    end
  end
end