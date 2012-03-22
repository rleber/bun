#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

module Bun
  class File < ::File
    class Descriptor
      class << self
        MAXIMUM_SIZE = 3000
        
        def maximum_size
          MAXIMUM_SIZE
        end
      end
      
      ARCHIVE_NAME_POSITION = 7 # words
      SPECIFICATION_POSITION = 11 # words
      DESCRIPTION_PATTERN = /\s+(.*)/
      FIELDS = [
        :description,
        :errors,
        :file_size,
        :file_type,
        :catalog_time,
        :name,
        :owner,
        :path,
        :specification,
        :tape_name,
        :tape_path,
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
      
      def size
        SPECIFICATION_POSITION + (specification.size + characters_per_word)/characters_per_word
      end
    
      def specification
        file.delimited_string SPECIFICATION_POSITION*CHARACTERS_PER_WORD, :all=>true
      end

      def owner
        file.delimited_string ARCHIVE_NAME_POSITION*CHARACTERS_PER_WORD, :all=>true
      end
    
      def subpath
        specification.sub(DESCRIPTION_PATTERN,'').sub(/^\//,'')
      end
    
      def subdirectory
        d = File.dirname(subpath)
        d = "" if d == "."
        d
      end

      def name
        File.basename(subpath)
      end
    
      def description
        specification[DESCRIPTION_PATTERN,1] || ""
      end
    
      def path
        File.relative_path(owner, subpath)
      end
    
      def unexpanded_path
        File.join(owner, subpath)
      end
      
      def tape
        File.basename(tape_path)
      end
      
      # TODO This isn't really relevant for non-frozen files; File::Frozen should really subclass this
      def updated
        file_time = self.file_time rescue nil
        if file_time && catalog_time
          [catalog_time, file_time].min
        elsif file_time
          file_time
        elsif catalog_time
          catalog_time
        else
          nil
        end
      end
      
      def shards
        file.shard_descriptor_hashes rescue []
      end
  
      def method_missing(meth, *args, &blk)
        file.send(meth, *args, &blk)
      rescue NoMethodError => e
        raise NoMethodError, %{"#{self.class}##{meth} method not defined:\n  Raised #{e} at:\n#{e.backtrace.map{|c| '    ' + c}.join("\n")}}
      end
    end
  end
end