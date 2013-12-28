#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

module Bun
  class File < ::File
    module Descriptor
      class Converted < Base
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
          :basename,
          :catalog_time,
          :description,
          :errors,
          :extracted,
          :file_size,
          :file_type,
          :tape,
          :tape_path,
          :original_tape,
          :original_tape_path,
          :owner,
          :path,
          :specification,
          :updated,
        ]
      
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

        def basename
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
      end
    end
  end
end