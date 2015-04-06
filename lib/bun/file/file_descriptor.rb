#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

module Bun
  class File < ::File
    module Descriptor
      class File < Base
        class << self
          MAXIMUM_SIZE = 3000
        
          def maximum_size
            MAXIMUM_SIZE
          end
        end
      
        ARCHIVE_NAME_POSITION = 7 # words
        SPECIFICATION_POSITION = 11 # words
        CHARACTERS_PER_WORD = 4
      
        DESCRIPTION_PATTERN = /\s+(.*)/
        FIELDS = [
          :description,
          :tape_size,
          :type,
          :tape,
          :owner,
          :path,
          :time,
        ]
      
        def size
          SPECIFICATION_POSITION + (specification.size + characters_per_word)/characters_per_word
        end
    
        def specification
          data.delimited_string SPECIFICATION_POSITION*CHARACTERS_PER_WORD, :all=>true
        end

        def owner
          data.delimited_string ARCHIVE_NAME_POSITION*CHARACTERS_PER_WORD, :all=>true
        end
            
        def raw_subpath
          specification.sub(DESCRIPTION_PATTERN,'').sub(/^\//,'')
        end

        def subpath
          path_parts = raw_subpath.split("/")
          path_parts = path_parts.map do |part|
            case part
            when "."
              "DOT"
            when ".."
              "DOTDOT"
            else
              part
            end
          end
          path = path_parts.join("/") 
        end
    
        def description
          specification[DESCRIPTION_PATTERN,1] || ""
        end
    
        def path
          Bun::File.relative_path(owner, subpath)
        end

        def subdirectory
          d = Bun::File.dirname(subpath)
          d = "" if d == "."
          d
        end
     
        def tape
          @tape ||= Bun::File.basename(tape_path)
          @tape
        end
        
        def tape=(name)
          @tape = name
        end
      end
    end
  end
end