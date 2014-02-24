#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

module Bun
  class File < ::File
    module Descriptor
      class Base
        VALID_FIELDS = {
        # :field_name   => "Field description",
          :block_count           => "The number of blocks in the file (one block contains 3,840 words)",
          :block_padding_repairs => "How many repairs of extra bits padding between blocks were made?",
          :catalog_time          => "The date and time of last update of the file (per the archive index)",
          :content               => "The content of this file (in external formats only)",
          :data                  => "The content of this file in binary form",
          :decode_time           => "The date and time at which this file was decoded",
          :decoded_by            => "An identifier of the version of the bun software that decoded this file",
          :description           => "Description of file (from Honeywell archive)",
          :digest                => "The MD5 checksum digest of the content of this file",
          :first_block_size      => "The size of the first block in this file (in 36-bit words)",
          :format                => "The format of this file (e.g. :packed, :unpacked, :decoded, :baked)",
          :identifier            => "Identifies this file as a bun file",
          :incomplete_file       => "This file was flagged as incomplete in the catalog",
          :llink_count           => "Number of llinks in the file (decoded text files only)",
          :owner                 => "The Honeywell username of the person who 'owned' this file",
          :path                  => "The relative path of the original file on the Honeywell",
          :shards                => {
                                      :desc=>"The description of the shards of a frozen file", 
                                      :default=>[]
                                    },
          :shard_blocks          => "The number of blocks in the original shard for this file (decoded shards only)",
          :shard_name            => "The name of the original shard for this file (decoded shards only)",
          :shard_number          => "The number of original shard for this file (decoded shards only)",
          :shard_size            => "The size of the original shard for this file in 36-bit words (decoded shards only)",
          :shard_start           => "The starting position of the original shard for this file (decoded shards only)",
          :shard_time            => "The date and time this file was originally created (decoded shards only)",
          :tape                  => "The name of the Honeywell tape archive this file came from",
          :tape_path             => "The path name of this tape file (not generally saved in the file)",
          :tape_size             => "The size of the archival tape file (in 36-bit words)",
          :time                  => "The date and time of last update of the file (frozen files only)",
          :text_size             => "The size of the decoded text (only for decoded files)",
          :type                  => "The type of Honeywell file contained in this file (i.e. :text, :frozen, :huffman)",
          :unpack_time           => "The date and time at which this file was unpacked",
          :unpacked_by           => "An identifier of the version of the bun software that unpacked this file",
        }

        SYNTHETIC_FIELDS = {
          :file                  => "The path of this file",
          :text                  => "The decoded text for the file",
          :earliest_time         => "The earliest recorded date for a file",
        }

        FILE_FIELDS = {
          :media_codes           => "Media codes for this file (only meaningful for text files)",
          :multi_segment         => "File contains lines split across blocks",
        }
      end
    end
  end
end