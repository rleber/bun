#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "huff", "Play around with Huffman encoded files"
def huff(file)
  check_for_unknown_options(file)
  File::Unpacked.open(file) do |f|
    # puts "f is a #{f.class}"
    # puts "words is a #{f.words.class}"
    # puts "words.size: #{f.words.size}"
    # puts "file size word: #{'%013o' % f.file_size_word}"
    # puts "number of characters: #{f.number_of_characters}"
    # puts "bits per byte: #{Bun::Data::BITS_PER_BYTE}"

    # puts f.tree.inspect

    # puts f.file_position

    puts f.text
  end
end