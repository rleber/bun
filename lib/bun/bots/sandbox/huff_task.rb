#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

module Bun
  class File < ::File
    class Huffman < ::Bun::File::Blocked
      class << self
        def open(path, options={}, &blk)
          File::Unpacked.open(path, options.merge(:type=>:huffman), &blk)
        end
      end
      def initialize(options={})
        options[:data] = Data.new(options) if options[:data] && !options[:data].is_a?(Bun::Data)
        super
      end

      def file_type
        word(content_offset).characters.join
      end

      def tree_offset
        content_offset + 2
      end
    end
  end
end

desc "huff", "Play around with Huffman encoded files"
def huff(file)
  check_for_unknown_options(file)
  File::Huffman.open(file) do |f|
    puts "words is a #{f.words.class}"
    puts "words.size: #{f.words.size}"
    puts "file_type: #{f.file_type}"
    10.times do |i|
      index = i + f.content_offset
      puts ('%4d' % index) + '  ' + ('%013o' % f.words.at(index))
    end
  end
end