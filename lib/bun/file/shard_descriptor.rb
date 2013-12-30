#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

module Bun
  class File < ::File
    module Descriptor
      class Shard < Base
        # attr_reader :character_count
        # attr_reader :control_characters
        attr_reader :data
        attr_reader :number
        attr_accessor :status

        DESCRIPTOR_OFFSET = 5
        DESCRIPTOR_SIZE = 10
        BLOCK_SIZE = 64  # 36-bit words
        DESCRIPTOR_END_MARKER = 0777777777777
        FIELDS = [
          :name,
          :file_time,
          :blocks,
          :start,
          :size,
        ]
        
        class << self
          def offset
            DESCRIPTOR_OFFSET
          end

          def size
            DESCRIPTOR_SIZE
          end

          def end_marker
            DESCRIPTOR_END_MARKER
          end

          # Is a file frozen?
          # Yes, if and only if it has a valid descriptor
          # def frozen?(file)
          #   file.words.at(file.content_offset + offset + size - 1) == end_marker
          # end
        end

        def initialize(data, number, options={})
          super(data.data)
          @number = number
          unless options[:allow] || valid?
            raise "Bad descriptor ##{number} for #{data.tape} at #{'%#o' % self.offset}:\n#{dump}" 
          end
        end
  
        def to_hash
          FIELDS.inject({}) {|hsh, f| hsh[f] = self.send(f) rescue nil; hsh }
        end

        def offset(n=nil) # Offset of the descriptor from the beginning of the file content, in words
          n ||= number
          data.content_offset + DESCRIPTOR_OFFSET + n*DESCRIPTOR_SIZE
        end

        def finish
          offset(number+1)-1
        end

        def characters(start, length)
          data.all_characters[offset*data.characters_per_word + start, length].join
        end
        
        def words(start, length)
          data.words[start+offset, length]
        end

        def word(start)
          data.words.at(start+offset)
        end

        def name
          characters(0,8).strip
        end
        
        def packed_update_date
          characters(8,8)
        end
        private :packed_update_date

        def packed_update_time_of_day
          word(4)
        end
        private :packed_update_time_of_day

        def file_time
          Bun::Data.time(packed_update_date, packed_update_time_of_day)
        end

        def blocks
          word(6).value
        end
        # 
        # def self.block_size
        #   BLOCK_SIZE  # In words
        # end
        # 
        # def block_size
        #   self.class.block_size
        # end

        def start
          word(7).value
        end

        def size
          word(8).value
        end
        alias_method :tape_size, :size

        def valid?
          # TODO Optimize Is this check necessary?
          return nil unless finish < data.words.size
          (check_text == 'asc ') && (check_word == DESCRIPTOR_END_MARKER)
        end

        def check_text
          characters(20,4)
        end

        def check_word
          word(9).value
        end
          
        def dump
          octal + "\ncheck_text: #{check_text.inspect}, check_word: #{'%#o' % check_word}"
        end
          
        def octal
          words(0, self.class.size).map{|w| '%012o' % w.value}.join(' ')
        end
      end
    end
  end
end