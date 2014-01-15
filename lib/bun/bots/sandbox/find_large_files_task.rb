#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "find_large_files ARCHIVE", "List files containing more than one chunk (a chunk contains a link, or 12 llinks)"
option 'padded', :aliases=>'-p', :type=>'boolean',                :desc=>"Display only files where the chunks are padded"
option 'quick',  :aliases=>'-q', :type=>'boolean',                :desc=>"Display files quickly (don't justify columns)"
option 'size',   :aliases=>'-s', :type=>'numeric', :default=>1.0, :desc=>"How many times larger than one chunk should the file be?"
option 'type',   :aliases=>'-t', :type=>'string',                 :desc=>"Show only files of this type"
def find_large_files(archive)
  check_for_unknown_options(archive)
  typ = case options[:type].to_s.downcase
    when 'f', 'frozen'
      :frozen
    when 't', 'text'
      :text
    when 'h', 'huff', 'huffman'
      :huffman
    when '', '*', 'a', 'all'
      nil
    else
      stop "!Unknown --type: #{options[:type]}"
  end
  table = [%w{File Words Chunk}]
  puts table.first.join('  ') if options[:quick]
  a = Archive.new(archive)
  a.leaves.each do |leaf|
    data = ::File.read(leaf)
    File::Packed.open(leaf) do |f|
      word_count = (f.word(0).to_i & 0777777) + 1
      next if options[:padded] && !word_count.odd?
      file_words = (data.size*8/36.0).ceil
      next unless file_words > options[:size]*word_count
      next if typ && File.tape_type(leaf) != typ
      table << [a.relative_path(leaf), file_words, word_count]
      puts table.last.join('  ') if options[:quick]
    end
  end
  unless options[:quick]
    puts table.justify_rows(right_justify: [1,2]).map{|row| row.join('  ')}
  end
end