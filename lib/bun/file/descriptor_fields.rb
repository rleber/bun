#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

module Bun
  class File < ::File
    module Descriptor
      class Base
        VALID_FIELDS = {
        # :field_name   => "Field description",
          :bcd                   => "Does this file contain BCD data?",
          :binary                => "Does this file contain binary (non-ASCII) data?",
          :block_count           => "The number of blocks in the file (one block contains 3,840 words)",
          :block_padding_repairs => "How many repairs of extra bits padding between blocks were made?",
          :catalog_time          => "The date and time of last update of the file (per the archive index)",
          :content               => "The content of this file (in external formats only)",
          :content_start         => "Where does the content start (Huffman files only)",
          :data                  => "The content of this file in binary form",
          :decodable             => "Is the file decodable? (Mostly true, except for executable files.)",
          :decode_time           => "The date and time at which this file was decoded",
          :decoded_by            => "An identifier of the version of the bun software that decoded this file",
          :description           => "Description of file (from Honeywell archive)",
          :digest                => "The MD5 checksum digest of the content of this file",
          :executable            => "Is this file a Honeywell executable?",
          :first_block_size      => "The size of the first block in this file (in 36-bit words)",
          :format                => "The format of this file (e.g. :packed, :unpacked, :decoded, :baked)",
          :identifier            => "Identifies this file as a bun file",
          :incomplete_file       => "This file was flagged as incomplete in the catalog",
          :llink_count           => "Number of llinks in the file (decoded text files only)",
          :media_codes           => "Media codes for this file (text files only)",
          :multi_segment         => "File contains lines split across blocks (text files only)",
          :owner                 => "The Honeywell username of the person who 'owned' this file",
          :path                  => "The relative path of the original file on the Honeywell",
          :sectors               => "How many sectors (64 words) in the file?",
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
          :type                  => "The type of Honeywell file contained in this file (i.e. :text, :frozen, :huffman, :huffword, :executable)",
          :unpack_time           => "The date and time at which this file was unpacked",
          :unpacked_by           => "An identifier of the version of the bun software that unpacked this file",
        }

        SYNTHETIC_FIELDS = {
          :file                  => "The path of this file",
          :text                  => "The decoded text for the file",
          :earliest_time         => "The earliest recorded date for a file",
          :full_path             => "File path plus shard name (if applicable)",
        }

        # Note several of these duplicate VALID_FIELDS. If that happens, the software looks first in the descriptor,
        # and will store the information permanently there, if it's available. If not, it looks in the file
        FILE_FIELDS = {
          :bcd                   => "Does this file contain BCD data?",
          :binary                => "Does this file contain binary (non-ASCII) data?",
          :content_start         => "Where does the content start (Huffman files only)",
          :executable            => "Is this file a Honeywell executable?",
          :media_codes           => "Media codes for this file (text files only)",
          :multi_segment         => "File contains lines split across blocks (text files only)",
          :sectors               => "How many sectors (64 words) in the file?",
        }
      end
    end
  end
end