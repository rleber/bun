#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

module Bun
  class File < ::File
    module Descriptor
      class Packed < File

        attr_accessor :allow_bad_times
        
        def initialize(data, options={})
          super(data)
          @allow_bad_times = options[:allow_bad_times]
          if type == :frozen
            register_fields :shards, :time
          end
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
          begin
            Bun::Data.internal_time(packed_update_date, packed_update_time_of_day)
          rescue Bun::Data::BadTime
            raise unless self.allow_bad_times
            Time.now
          end
        end
    
        def shards(options={})
          return @shards if @shards
          @shards = Shards.new
          shard_count.times do |i|
            shard_hash = Descriptor::Shard.new(self, i, allow: !options[:strict]).to_hash
            break unless shard_hash # Stop at bad descriptor
            @shards << shard_hash
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