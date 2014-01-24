#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

module Bun
  class File < ::File
    module Descriptor
      class Packed < Base
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
        
        def initialize(*args)
          super
          if type == :frozen
            register_fields :shards, :time
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
          @tape ||= File.basename(tape_path)
          @tape
        end
        
        def tape=(name)
          @tape = name
        end
        
              
        def shard_count
          type == :frozen ? words.at(content_offset+1).half_words.at(1).to_i : 0
        end
        
        def tape_size
          type == :frozen ? data.frozen_tape_size : data.tape_size
        end
      
        # Reference to all_characters is necessary here, because characters isn't
        # available in header files. Still, it seems a bit kludgy...
        def packed_update_date
          all_characters[(content_offset + 2)*characters_per_word, 8].join
        end
        private :packed_update_date
        
        def packed_update_time_of_day
          words.at(content_offset + 4)
        end
        private :packed_update_time_of_day
    
        def time
          return nil unless type == :frozen
          Bun::Data.time(packed_update_date, packed_update_time_of_day)
        end
    
        def shards
          return @shards if @shards
          @shards = Shards.new
          shard_count.times do |i|
            @shards << Descriptor::Shard.new(self, i).to_hash
          end
          @shards
        end

        def type
          data.type
        end

        def format
          :packed
        end
      end
    end
  end
end