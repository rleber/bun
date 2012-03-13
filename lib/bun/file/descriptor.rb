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
      
      attr_reader :file
      
      def initialize(file)
        @file = file
      end
    
      def size
        SPECIFICATION_POSITION + (specification.size + characters_per_word)/characters_per_word
      end
    
      def specification
        file.delimited_string SPECIFICATION_POSITION*CHARACTERS_PER_WORD, :all=>true
      end
    
      def archive_name
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
        File.relative_path(archive_name, subpath)
      end
    
      def unexpanded_path
        ::File.join(archive_name, subpath)
      end
    
      def characters_per_word
        file.characters_per_word
      end
    end
  end
end