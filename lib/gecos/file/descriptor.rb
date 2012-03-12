class GECOS
  class File
    class Descriptor
      class << self
        MINIMUM_LENGTH = 256
        
        def minimum_length
          MINIMUM_LENGTH
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
        delimited_string SPECIFICATION_POSITION*CHARACTERS_PER_WORD
      end
    
      def archive_name
        delimited_string ARCHIVE_NAME_POSITION*CHARACTERS_PER_WORD
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
        self.class.relative_path(archive_name, subpath)
      end
    
      def unexpanded_path
        File.join(archive_name, subpath)
      end
    
      def characters_per_word
        file.characters_per_word
      end
    end
  end
end