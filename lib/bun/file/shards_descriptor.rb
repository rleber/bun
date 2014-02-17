#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

module Bun
  class File < ::File
    module Descriptor
      class Shards < ::Array
        # Fields:
        #   :name
        #   :time
        #   :blocks
        #   :start
        #   :size
        class Entry < Hashie::Mash
          def initialize(shard, number)
            super(shard)
            self.number = number
          end

          def size
            self[:size]
          end

          def inspect
            self.to_hash.symbolized_keys.inspect
          end
        end

        def initialize(shards=[])
          shards ||= []
          shards.each do |shard|
            self << shard
          end
        end

        def <<(shard)
          shard = Entry.new(shard, self.size) unless shard.is_a?(Entry)
          super(shard)
        end

        def [](index)
          if index.is_a?(Numeric) || (index.is_a?(String) && index =~ /^[-+]?\d+$/)
            super(index.to_i)
          else
            self.find {|entry| entry.name == index }
          end
        end
      end
    end
  end
end
