#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

module Bun
  class File < ::File
    module Huffman
      module Data
        class Base < Bun::Data
          include CacheableMethods

          class BadFileContentError < RuntimeError; end
          class TreeTooDeepError < RuntimeError; end

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

            def []=(i,value)
              @array[i] = value
              if i==0
                @left = value
              else
                @right = value
              end
              value
            end

            def inspect
              "(#{@left.inspect},#{@right.inspect})"
            end
          end

          attr_reader :file_position, :bit_position, :characters_left
          attr_reader :current_character, :current_byte, :current_bit, :content_start

          def initialize(options={})
            super
          end

          def reset_position
            @file_byte_position = 0
            @bit_position = 0
          end

          def file_type_code
            word(content_offset).characters.join
          end

          # Should NOT appear in normal Huffman files, but does appear in Huffword files
          def file_table_marker
            word(content_offset+2).characters.join
          end

          def file_size_word
            word(content_offset+1)
          end

          def bcd
            false
          end

          def tree_offset
            content_offset + 2
          end

          def tree
            @tree ||= reset
          end

          def encoding(tree, bits="")
            if tree.left
              encoding(tree.left, bits+"0").merge(encoding(tree.right, bits+"1"))
            else
              {bits=>tree.right}
            end
          end

          def dump_tree(tree, options={})
            stream = options[:to] || $stdout
            indent = options[:indent] || 0
            pad = ' '*indent
            tbl = encoding(tree)
            key_len = tbl.keys.map{|key| format_key(key, 0).size}.max
            tbl.keys.sort.each do |key|
              stream.puts "#{pad}#{format_key(key, key_len)}: #{format_characters(tbl[key])}"
            end
          end

          def format_key(key, key_len)
            "%-#{key_len}s" % key
          end

          def file_byte(n)
            n += tree_offset*Bun::Data::BYTES_PER_WORD
            w, byte = n.divmod(Bun::Data::BYTES_PER_WORD)
            word(w) && word(w).bytes[byte]
          end

          def get_file_byte
            @file_byte_position ||= 0
            @current_byte = file_byte(@file_byte_position)
            @file_byte_position += 1
            @bit_position = 0
            @current_byte
          end

          def get_bit
            @bit_position ||= 0
            get_file_byte if @bit_position >= Bun::Data::BITS_PER_BYTE
            if @current_byte
              @current_bit = (@current_byte >> (Bun::Data::BITS_PER_BYTE - @bit_position - 1)) & 01
              @bit_position += 1
            else
              @current_bit = nil
            end
            @current_bit
          end

          def get_decoded_byte
            start_text unless @tree
            if !@characters_left.nil? && @characters_left <= 0
              @current_character = nil
            else
              ch = nil
              tree = @tree
              loop do 
                if tree.left
                  b = get_bit
                  if b
                    tree = tree[b]
                  else
                    debug "Unexpected tree node"
                    return nil
                  end
                else
                  ch = tree.right
                  break
                end
              end
              @characters_left -= 1 if @characters_left
              @current_character = ch
            end
          end

          def decoded_bytes
            s = []
            while ch = get_decoded_byte
              s << ch
            end
            s
          end
          cache :decoded_bytes

          def dump_bits(options={})
            start = options[:start] || [@file_byte_position, @bit_position]
            limit = options[:limit]
            width = options[:width] || 80
            stream = options[:to] || $stdout
            indent = options[:indent] || 0
            pad = ' '*indent
            save_file_position = @file_byte_position
            save_bit_position = @bit_position
            save_current_byte = @current_byte
            @file_byte_position, @bit_position = start
            bits = ""
            bit_count = 0
            stream.puts "#{pad}Bits at position #{@file_byte_position}:#{@bit_position} ".ljust(width, "-")
            loop do
              bit = get_bit
              bit_count += 1 if bit
              if bits.size >= width || bit.nil? || (limit && bit_count >= limit)
                stream.puts pad + bits
                bits = ""
              end
              break unless bit
              break if limit && bit_count >= limit
              bits += bit == 0 ? "0" : "1"
            end
            @file_byte_position = save_file_position
            @bit_position = save_bit_position
            @current_byte = save_current_byte
          end

          def text
            if binary
              stop "!Encoding binary Huffman file"
              w = Bun::Words.new
              decoded_bytes.each_slice(4) do |bytes|
                w << Bun::Word.pack_bytes(*bytes)
              end
              w.pack
            else
              decoded_bytes.map do |byte|
                byte_to_text(byte)
              end.join
            end
          end
          cache :text

          def decoded_text(options={})
            text
          end
        end
      end
    end
  end
end
