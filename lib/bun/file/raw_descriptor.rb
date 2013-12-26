#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

module Bun
  class File < ::File
    module Descriptor
      class Raw < Base
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
          # :basename,
          # :catalog_time,
          :description,
          # :errors,
          # :extracted,
          :file_size,
          :file_type,
          :tape,
          # :tape_path,
          # :original_tape,
          # :original_tape_path,
          :owner,
          :path,
          # :specification,
          :file_time,
          # :updated,
        ]
        
        def initialize(*args)
          super
          if file_type == :frozen
            register_fields :shards, :file_time
          end
        end
      
        def size
          SPECIFICATION_POSITION + (specification.size + characters_per_word)/characters_per_word
        end
    
        def specification
          data.delimited_string SPECIFICATION_POSITION*CHARACTERS_PER_WORD, :all=>true
        end

        def owner
          data.delimited_string ARCHIVE_NAME_POSITION*CHARACTERS_PER_WORD, :all=>true
        end
            
        def subpath
          specification.sub(DESCRIPTION_PATTERN,'').sub(/^\//,'')
        end
        #     
        # def subdirectory
        #   d = File.dirname(subpath)
        #   d = "" if d == "."
        #   d
        # end
        # 
        # def basename
        #   File.basename(subpath)
        # end
    
        def description
          specification[DESCRIPTION_PATTERN,1] || ""
        end
    
        def path
          File.relative_path(owner, subpath)
        end
        #     
        # def unexpanded_path
        #   File.join(owner, subpath)
        # end
      
        def tape
          File.basename(tape_path)
        end
        
              
         # # TODO This isn't really relevant for non-frozen files; File::Frozen should really subclass this
         # def updated
         #   file_time = self.file_time rescue nil
         #   if file_time && catalog_time
         #     [catalog_time, file_time].min
         #   elsif file_time
         #     file_time
         #   elsif catalog_time
         #     catalog_time
         #   else
         #     nil
         #   end
         # end
        #        
        def shard_count
          file_type == :frozen ? words.at(content_offset+1).half_words.at(1).to_i : 0
        end
        
        def file_size
          file_type == :frozen ? data.frozen_file_size : data.file_size
        end
      
        # Reference to all_characters is necessary here, because characters isn't
        # available in header files. Still, it seems a bit kludgy...
        def raw_update_date
          all_characters[(content_offset + 2)*characters_per_word, 8].join
        end
        private :raw_update_date
        
        def raw_update_time_of_day
          words.at(content_offset + 4)
        end
        private :raw_update_time_of_day
    
        def file_time
          return nil unless file_type == :frozen
          Bun::Data.time(raw_update_date, raw_update_time_of_day)
        end
    
        def shards
          return @shards if @shards
          @shards = []
          shard_count.times do |i|
            @shards << Descriptor::Shard.new(self, i).to_hash
          end
          @shards
        end

      end
    end
  end
end