#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

module Bun
  class File < ::File
    class Blocked < Bun::File
      include CacheableMethods
      
      attr_accessor :status
      attr_accessor :strict
      attr_reader   :good_blocks
      
      def initialize(options={}, &blk)
        super
        @strict = options[:strict]
        descriptor.register_fields(:blocks, :good_blocks, :status)
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
        (size - content_offset).div(BLOCK_SIZE)
      end
    
      # TODO Build a capability in Slicr to do things like this
      def deblocked_content
        deblocked_content = []
        offset = 0
        block_number = 1
        self.status = :readable
        @good_blocks = 0
        loop do
          break if offset >= file_content.size
          break if file_content.at(offset) == 0
          block_size = file_content.at(offset).byte(3)
          unless file_content[offset].half_word[0] == block_number
            if strict
              raise "Bad block number #{block_number} in #{tape} at #{'%#o' % (offset+content_offset)}: expected #{'%07o' % block_number}; got #{file_content[offset].half_word[0]}"
            else
              error "Truncated before block #{block_number} at #{'%#o' % (offset+content_offset)}"
              if block_number == 1
                self.status = :unreadable
              else
                self.status = :truncated
              end
              break
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