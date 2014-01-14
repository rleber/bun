#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

module Bun
  class File < ::File
    class Unpacked < Bun::File
      class Huffman < ::Bun::File::Blocked
        class BadFileContentError < RuntimeError; end

        class TreeNode
          attr_accessor :left, :right, :array
          def initialize(left, right)
            @left = left
            @right = right
            @array = [@left, @right]
          end

          def [](i)
            @array[i]
          end

          def inspect
            if @left
              "(#{@left.inspect},#{@right.inspect})"
            else
              @right.inspect
            end
          end
        end

        class << self
          def open(path, options={}, &blk)
            File::Unpacked.open(path, options.merge(:type=>:huffman), &blk)
          end
        end

        attr_reader :file_position, :bit_position, :characters_left
        attr_reader :current_character, :current_byte, :current_bit

        def initialize(options={})
          options[:data] = Data.new(options) if options[:data] && !options[:data].is_a?(Bun::Data)
          super
          raise BadFileContentError, "Does not appear to be a Huffman file" unless file_type_code == "huff"
          reset_position
        end

        def reset_position
          @file_position = 0
          @bit_position = 0
        end

        def file_type_code
          word(content_offset).characters.join
        end

        def file_size_word
          word(content_offset+1)
        end

        def number_of_characters
          (file_size_word >> 18).to_i
        end

        def tree_offset
          content_offset + 2
        end

        def tree_byte(n)
          n += tree_offset*Bun::Data::BYTES_PER_WORD
          w, byte = n.divmod(Bun::Data::BYTES_PER_WORD)
          word(w) && word(w).bytes[byte]
        end

        def tree
          @tree ||= reset
        end

        def reset
          reset_position
          @tree = build_sub_tree(get_byte)
          @characters_left = number_of_characters
          @tree
        end

        def build_sub_tree(ch)
          if ch==0
            TreeNode.new(nil, get_byte.chr)
          else
            TreeNode.new(build_sub_tree(ch-1),build_sub_tree(get_byte))
          end
        end
        private :build_sub_tree

        def get_byte
          @file_position ||= 0
          @current_byte = tree_byte(@file_position)
          @file_position += 1
          @current_byte
        end

        def get_bit
          @bit_position ||= 0
          if @bit_position >= Bun::Data::BYTES_PER_WORD
            get_byte
            @bit_position = 0
          end
          if @current_byte
            @current_bit = (@current_byte >> (Bun::Data::BITS_PER_BYTE - @bit_position - 1)) & 01
            @bit_position += 1
          else
            @current_bit = nil
          end
          @current_bit
        end

        def get_char
          reset unless @tree
          if @characters_left <= 0
            @current_character = nil
          else
            ch = nil
            tree = @tree
            loop do 
              if tree.left
                b = get_bit
                if b
                  tree = tree[get_bit]
                else
                  return nil
                end
              else
                ch = tree.right
                break
              end
            end
            @characters_left -= 1
            @current_character = ch
          end
        end

        def text
          reset
          s = ""
          while ch = get_char
            s << ch
          end
          s
        end
      end
    end
  end
end
