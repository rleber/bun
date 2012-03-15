class Bun
  class File
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
        :file_size,
        :file_type,
        :index_date,
        :name,
        :owner,
        :path,
        :shard_count,
        :shard_names,
        :specification,
        :tape_name,
        :tape_path,
        :update_date,
        :update_time,
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
        d = ::File.dirname(subpath)
        d = "" if d == "."
        d
      end

      def name
        ::File.basename(subpath)
      end
    
      def description
        specification[DESCRIPTION_PATTERN,1] || ""
      end
    
      def path
        File.relative_path(owner, subpath)
      end
    
      def unexpanded_path
        ::File.join(owner, subpath)
      end
    
      def characters_per_word
        file.characters_per_word
      end
      
      def index_date
        file.archive && file.archive.index_date(tape)
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
        ::File.basename(tape_path)
      end
      
      def update_date
        file.update_date rescue nil
      end
      
      def update_time
        file.update_time rescue nil
      end
      alias_method :updated, :update_time
      
      def index_date
        file.index_date rescue nil
      end
      
      def updated
        update_time || index_date
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