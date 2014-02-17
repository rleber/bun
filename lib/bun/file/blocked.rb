#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

module Bun
  class File < ::File
    class Blocked < Bun::File::Unpacked

      include CacheableMethods
      
      attr_accessor :status
      attr_accessor :strict
      attr_reader   :good_blocks
      attr_reader   :llink_count
      
      def initialize(options={}, &blk)
        super
        @strict = options[:strict]
        @llink_count = nil
        # descriptor.register_fields(:blocks, :good_blocks, :status)
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
      
      def file_content
        data.file_content
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
        link_number = 1
        llink_number = 1
        loop do 
          # Process a link
          break if offset >= words.size
          bcw = words.at(offset)
          break if bcw.to_i == 0
          # debug "link: offset: #{offset}(0#{'%o' % offset}): #{'%013o' % words.at(offset)}"
          # debug "preamble: offset: #{offset+1}(0#{'%o' % (offset+1)}): #{'%013o' % words.at(offset+1)}"
          link_sequence_number = bcw.half_word[0].to_i
          raise BadBlockError, "Link out of sequence at #{offset}(0#{'%o'%offset}): Found #{link_sequence_number}, expected #{link_number}. BCW #{'%013o' % bcw.to_i}" \
            unless link_sequence_number == link_number
          next_link = bcw.half_word[1].to_i + offset + 1
          # debug "next link: #{'%013o' % next_link}"
          preamble_length = words.at(offset+1).half_word[1].to_i
          offset += preamble_length
          loop do
            # debug "llink: offset: #{offset}(0#{'%o' % offset}): #{'%013o' % words.at(offset)}"
            break if offset >= words.size || offset >= next_link
            break if words.at(offset) == 0
            block_size = words.at(offset).byte(3)
            unless words.at(offset).half_word[0] == block_number
              if strict
                raise "Llink out of sequence in #{location} at #{'%#o' % (offset+content_offset)}: expected #{'%07o' % block_number}; got #{file_content[offset].half_word[0]}"
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
            deblocked_content += words[offset+1..(offset+block_size)].to_a
            offset += BLOCK_SIZE
            block_number += 1
            @good_blocks += 1
          end
          offset = next_link
          link_number += 1
        end
        @llink_count = link_number
        Bun::Words.new(deblocked_content)
      end
      cache :deblocked_content

      def llink_count
        unless @llink_count
          _ = deblocked_content
          descriptor.merge!(llink_count: @llink_count)
        end
        @llink_count
      end
    end
  end
end