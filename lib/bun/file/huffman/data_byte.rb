#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

module Bun
  class File < ::File
    module Huffman
      module Data
        class Byte < Base

          class BadFileContentError < RuntimeError; end
          class TreeTooDeepError < RuntimeError; end

          def initialize(options={})
            super
            raise BadFileContentError, "Does not appear to be a Huffman file: file type word=#{file_type_code.inspect} (should be 'huff')" \
              unless file_type_code == "huff"
            raise BadFileContentError, "Does not appear to be a Huffman byte file: file table marker should not be 'tabl'" \
              unless file_table_marker != "tabl"
            start_text
          end

          def binary
            decoded_bytes.any? {|byte| byte > 255 }
          end

          def number_of_characters
            (file_size_word >> 18 & 0377777).to_i
          end

          def format_characters(chars)
            chars.chr.inspect
          end

          def reset
            reset_position
            @characters_left = number_of_characters
            @tree = make_tree # Must rebuild tree, in order to find the end of the tree description
                              # That is the start of the encoded text.
          end

          def start_text
            reset
            get_file_byte 
            @content_start = @file_byte_position
          end

          def make_tree
            build_sub_tree(get_file_byte, 0)
          end

          RECURSION_LIMIT = 500

          def build_sub_tree(ch, depth)
            raise TreeTooDeepError, "Huffman tree too deep: more than #{RECURSION_LIMIT} bits in encoding" \
              if depth > RECURSION_LIMIT
            if ch==0
              TreeNode.new(nil, get_file_byte)
            else
              TreeNode.new(build_sub_tree(ch-1, depth+1),build_sub_tree(get_file_byte, depth+1))
            end
          end
          private :build_sub_tree

          def byte_to_text(byte)
            byte > 255 ? "\\o{#{'%o'%byte}}" : byte.chr
          end
        end
      end
    end
  end
end
