#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

module Bun
  class File < ::File
    module Descriptor
      class Unpacked < File

        FIELDS = [
          :basename,
          :catalog_time,
          :description,
          :errors,
          :decoded,
          :tape_size,
          :type,
          :tape,
          :tape_path,
          :original_tape,
          :original_tape_path,
          :owner,
          :path,
          :specification,
          :updated,
        ]

        # TODO This isn't really relevant for non-frozen files; File::Frozen should really subclass this
        def updated
          time = self.time rescue nil
          if time && catalog_time
            [catalog_time, time].min
          elsif time
            time
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