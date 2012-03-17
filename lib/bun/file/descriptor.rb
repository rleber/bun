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
        :blocks,
        :description,
        :file_size,
        :file_type,
        :good_blocks,
        :catalog_time,
        :name,
        :owner,
        :path,
        :shard_count,
        :shard_names,
        :specification,
        :tape_name,
        :tape_path,
        :file_date,
        :file_time,
        :updated,
      ]
      
      attr_reader :file
      
      def initialize(file)
        @file = file
      end
      
      def self.fields
        FIELDS
      end
      
      def to_hash
        FIELDS.inject({}) {|hsh, f| hsh[f] = self.send(f) rescue nil; hsh }
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
    
      def characters_per_word
        file.characters_per_word
      end
      
      def tape_name
        file.tape_name
      end
      
      def tape_path
        file.tape_path
      end
      
      def file_type
        file.file_type
      end
      
      def tape
        File.basename(tape_path)
      end
      
      def file_date
        file.file_date rescue nil
      end
      
      def file_time
        file.file_time rescue nil
      end
      
      def updated
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
      
      def blocks
        file.blocks rescue nil
      end
      
      def good_blocks
        file.good_blocks rescue nil
      end
      
      def catalog_time
        file.catalog_time rescue nil
      end
      
      def type
        file.type
      end
      
      def shard_names
        file.shard_names rescue []
      end
      
      def shard_count
        file.shard_count rescue 0
      end
      
      def file_size
        file.file_size
      end
    end
  end
end