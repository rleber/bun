#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

module Bun
  class File < ::File
    class Frozen
      class Descriptor
        attr_reader :character_count
        attr_reader :control_characters
        attr_reader :file
        attr_reader :number
        attr_accessor :status

        DESCRIPTOR_OFFSET = 5
        DESCRIPTOR_SIZE = 10
        BLOCK_SIZE = 64  # 36-bit words
        DESCRIPTOR_END_MARKER = 0777777777777
        FIELDS = [
          :tape_size,
          :type,
          :catalog_time,
          :control_characters,
          :character_count,
          :name,
          :owner,
          :path,
          :status,
          :tape,
          :tape_path,
          :file_date,
          :time,
          :updated,
        ]
        
        INDEXED_FIELDS = [:control_characters, :character_count]
        
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
          def frozen?(file)
            file.words.at(file.content_offset + offset + size - 1) == end_marker
          end
        end

        def initialize(file, number, options={})
          @file = file
          @number = number
          raise "Bad descriptor ##{number} for #{file.tape} at #{'%#o' % self.offset}:\n#{dump}" unless options[:allow] || valid?
          load_fields_from_archive
        end
  
        def to_hash
          FIELDS.inject({}) {|hsh, f| hsh[f] = self.send(f) rescue nil; hsh }
        end
        
        def load_fields_from_archive
          return unless @file.archive
          archive_descriptor = @file.archive.descriptor(tape)
          return unless archive_descriptor
          shard_descriptor = archive_descriptor.shards[number]
          return unless shard_descriptor
          INDEXED_FIELDS.each do |field|
            next unless shard_descriptor[field]
            self.instance_variable_set("@#{field}", shard_descriptor[field])
          end
        end

        def offset(n=nil) # Offset of the descriptor from the beginning of the file content, in words
          n ||= number
          file.content_offset + DESCRIPTOR_OFFSET + n*DESCRIPTOR_SIZE
        end

        def finish
          offset(number+1)-1
        end
        
        def control_characters=(value)
          raise "nil assigned to control_characters for #{tape}[#{name}]" if value.nil?
          # raise "{} assigned to control_characters for #{tape}[#{name}]" if value == {}
          @control_characters = value
        end
        
        def character_count=(count)
          raise "nil assigned to character_count for #{tape}[#{name}]" if count.nil?
          @character_count = count
        end
    
        def characters(start, length)
          @file.all_characters[offset*file.characters_per_word + start, length].join
        end

        def words(start, length)
          @file.words[start+offset, length]
        end

        def word(start)
          @file.words.at(start+offset)
        end

        def name
          characters(0,8).strip
        end
  
        def owner
          file.owner
        end
  
        def type
          :shard
        end

        def path
          File.relative_path(file.path, name)
        end
  
        def tape
          file.tape
        end
  
        def tape_path
          file.tape_path
        end

        def file_date
          File::Unpacked.date(_update_date)
        end

        def _update_date
          characters(8,8)
        end

        def update_time_of_day
          File::Unpacked.time_of_day(_update_time_of_day)
        end

        def _update_time_of_day
          word(4)
        end
  
        def catalog_time
          file.catalog_time
        end

        def time
          Bun::Data.internal_time(_update_date, _update_time_of_day)
        end
        alias_method :updated, :time

        def blocks
          word(6).value
        end

        def self.block_size
          BLOCK_SIZE  # In words
        end

        def block_size
          self.class.block_size
        end

        def start
          word(7).value
        end

        def size
          word(8).value
        end
        alias_method :tape_size, :size

        def valid?
          # TODO Optimize Is this check necessary?
          return nil unless finish < @file.words.size
          (check_text == 'asc ') && (check_word == DESCRIPTOR_END_MARKER)
        end

        def check_text
          characters(20,4)
        end

        def check_word
          word(9)
        end

        def hex
          words(offset, self.class.size).map{|w| '%#x' % w.value}.join(' ')
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