#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

module Bun
  class File < ::File
    module Huffman
      module Data
        class Plus < Base

          def initialize(options={})
            super
            raise BadFileContentError, "Does not appear to be a Huffword file: file type word=#{file_type_code.inspect} (should be 'huff')" \
              unless file_type_code == "huff"
            raise BadFileContentError, "Does not appear to be a Huffword word file: file table marker=#{file_table_marker.inspect} (should be 'tabl')" \
              unless file_table_marker == "tabl"
            start_text
          end

          def item_count
            word(content_offset+3).to_i
          end

          def compressed_table
            file_size_word & 0600000000000 == 0600000000000
          end

          def words_per_table_entry
            compressed_table ? 2 : 3
          end

          def binary
            decoded_bytes.map {|byte| expand_byte(byte) }.flatten.any? {|byte| byte >= 256 }
          end

          def format_characters(chars)
            return "nil" unless chars
            chs = chars.map do |ch|
              if ch.is_a?(Symbol)
                ch.inspect
              elsif ch < 256
                ch.chr.inspect
              else
                '0' + ('%o' % ch)
              end
            end
            if chs.size > 1
              chs = "[#{chs.join(',')}]"
            else
              chs = chs[0]
            end
            chs
          end

          EOF_BYTES = [0777, 0777]
          REPEAT_BYTES = [0777, 0776]

          def tree_entry(n)
            w = tree_offset+2+n*words_per_table_entry
            @file_word_position = w+words_per_table_entry
            return nil if n>item_count
            if compressed_table
              wd = word(w).to_i
              ch = wd >> 18
              bits = wd & 0177777
              code = get_code(word(w+1).to_i, bits)
            else
              ch = word(w).to_i
              bits = word(w+1).to_i
              code = get_code(word(w+2).to_i, bits)
            end
            return nil unless bits>0
            chs = Bun::Word.new(ch).bytes.reject{|byte| byte==0}.map{|byte| byte.to_i}
            case chs
            when EOF_BYTES
              chs = [:eof]
            when REPEAT_BYTES
              chs = [:repeat]
            end
            {chars: chs, code: code}
          end

          def print_tree_entries(entries, options={})
            stream = options[:to] || $stdout
            indent = options[:indent] || 0
            pad = ' '*indent
            key_len = entries.map{|entry| format_key(entry[:code], 0).size}.max
            entries.each do |entry|
              stream.puts "#{pad}#{format_key(entry[:code], key_len)}: #{format_characters(entry[:chars])}"
            end
          end

          def get_code(word, bits)
            "%0#{bits}b" % word
          end

          def tree
            @tree ||= reset
          end

          def reset
            reset_position
            @characters_left = nil
            @tree = make_tree # Must rebuild tree, in order to find the end of the tree description
                              # That is the start of the encoded text.
          end

          def start_text
            reset
            find_text_start
            @file_byte_position = @file_word_position*Bun::Data::BYTES_PER_WORD
            @content_start = @file_byte_position
            get_file_byte 
          end

          def make_tree
            build_tree(read_tree)
          end

          def read_tree
            entries = []
            item_count.times do |i|
              entry = tree_entry(i)
              break unless entry
              entries << entry
            end
            entries
          end

          def find_text_start
            while word(@file_word_position) == 0
              @file_word_position += 1
            end
            unless word(@file_word_position).characters.join == 'text'
              (-10..10).each {|i| puts "#{'%2d'%(@file_word_position+i)}: #{word(@file_word_position+i)}"}
            end
            raise BadFileContentError, "Missing 'text' marker at position #{@file_word_position}: #{word(@file_word_position)}" \
              unless word(@file_word_position).characters.join == 'text'
            @file_word_position += 1
          end

          def build_tree(entries)
            @tree = nil
            entries.each do |entry|
              add_entry(entry)
            end
            @tree
          end

          def add_entry(entry)
            node = find_node(entry[:code])
            node.left = nil
            node.right = entry[:chars]
          end

          def find_node(code)
            @tree ||= TreeNode.new(nil, nil)
            bits = code.split(//)
            subtree = @tree
            loop do
              next_bit = bits.shift
              return subtree unless next_bit
              next_bit = next_bit.to_i
              subtree[next_bit] ||= TreeNode.new(nil, nil)
              subtree = subtree[next_bit]
            end
            nil # Should never happen
          end

          def get_decoded_byte
            b = super
            case b
            when [:eof]
              nil
            when [:repeat]
              repeat_count = 8.times.map {|i| get_bit==0 ? 0 : 1<<(7-i)}.sum
              ch = super
              res = [:repeat, repeat_count, ch]
              res
            else
              b
            end
          end

          def expand_byte(byte)
            res = if byte.is_a?(Array)
              if byte[0]==:repeat
                byte[2]*byte[1]
              else
                byte
              end
            else
              [byte]
            end
            res.flatten
          end

          def byte_to_text(byte)
            bytes = expand_byte(byte)
            res = bytes.map do |b|
              if b>=256
                "%o{0#{'%o'%b}}"
              else
                b.chr
              end
            end.join("\b")
          end
        end
      end
    end
  end
end
