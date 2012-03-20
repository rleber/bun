#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

module Bun
  class File < ::File
    class Blocked < Bun::File
      include CacheableMethods
      
      attr_accessor :truncate
      attr_reader   :good_blocks
      
      def initialize(options={}, &blk)
        super
        @truncate = options[:truncate]
      end

      def words=(words)
        super
        if @words.nil?
          @deblocked_content = nil
        end
        words
      end
      
      def reblock
        @deblocked_content = nil
      end
    
      def content
        deblocked_content
      end
      
      BLOCK_SIZE = 0500 # words
      
      def blocks
        (file.size - content_offset).div(BLOCK_SIZE)
      end
    
      # TODO Build a capability in Slicr to do things like this
      def deblocked_content
        deblocked_content = []
        offset = 0
        block_number = 1
        @good_blocks = 0
        loop do
          break if offset >= file_content.size
          break if file_content.at(offset) == 0
          block_size = file_content.at(offset).byte(3)
          unless file_content[offset].half_word[0] == block_number
            if truncate
              error "Truncated before block #{block_number} at #{'%#o' % (offset+content_offset)}"
              break
            else
              raise "Bad block number #{block_number} in #{tape} at #{'%#o' % (offset+content_offset)}: expected #{'%07o' % block_number}; got #{file_content[offset].half_word[0]}"
            end
          end
          deblocked_content += file_content[offset+1..(offset+block_size)].to_a
          offset += BLOCK_SIZE
          block_number += 1
          @good_blocks += 1
        end
        Bun::Words.new(deblocked_content)
      end
      cache :deblocked_content
    end
  end
end