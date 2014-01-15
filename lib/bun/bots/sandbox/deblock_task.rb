#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "deblock FILE [TO]", "Remove tape archive chunks from file"
def deblock(file, to='-')
  check_for_unknown_options(file, to)
  File::Packed.open(file) do |f|
    puts "file size: #{f.data.words.size}"
    hex = f.data.data.to_hex
    puts "nybbles in file: #{hex.size}"
    first_chunk_prefix = f.data.word(0).to_i
    chunk_number = first_chunk_prefix >> 18
    chunk_size = (first_chunk_prefix & 0777777) + 1
    first_preamble_prefix = f.data.word(1).to_i
    puts "chunk_number: #{chunk_number}"
    puts "chunk_size: #{chunk_size}"
    stop "!Bad chunk number: #{chunk_number}" unless chunk_number==1
    nybbles_per_chunk = chunk_size * 36 / 4
    puts "nybbles per chunk: #{nybbles_per_chunk}"
    nybbles_per_padded_chunk = nybbles_per_chunk
    nybbles_per_padded_chunk += 1 if nybbles_per_chunk.odd?
    puts "nybbles per padded chunk: #{nybbles_per_padded_chunk}"
    offset = 0
    chunks = []
    while offset < hex.size
      chunk = hex[offset, nybbles_per_padded_chunk]
      offset += nybbles_per_padded_chunk
      if nybbles_per_chunk.odd?
        puts "Last nibble on padded chunk #{chunks.size+1}: #{chunk[-1]}"
        chunk.slice!(-1) 
      end
      chunks << chunk
      puts "Chunk #{chunks.size} size: #{chunks.last.size}, words: #{(chunks.last.size) * 4 /36.0}"
    end
    puts "number of chunks: #{chunks.size}"
    non_padded_chunks = chunks.select {|chunk| chunk[-1] != '0' }
    puts "number of non-padded chunks: #{non_padded_chunks.size}"
    odd_sized_chunks = chunks.select {|chunk| chunk.size.odd? }
    puts "number of odd-sized chunks: #{odd_sized_chunks.size}"
    puts "size of last chunk: #{(chunks[-1].size) *4 /36.0}"
    chunks[-1] = chunks[-1] + '0'*((9-(chunks[-1].size % 9)) % 9)
    puts "size of last chunk, after padding: #{(chunks[-1].size) *4 /36.0}"
    chunk_words = chunks.map{|chunk| Bun::Words.import([chunk].pack('H*'))}
    chunk_words.each.with_index do |chunk, index|
      this_chunk_prefix = chunk.at(0).to_i
      this_chunk_index  = this_chunk_prefix >> 18
      this_chunk_size = (this_chunk_prefix & 0777777) + 1
      this_preamble_prefix = chunk.at(1).to_i
      this_preamble_index =  this_preamble_prefix >> 18
      this_preamble_offset = (this_preamble_prefix & 0777777)
      stop "!Bad chunk (##{index+1}): Chunk index out of sequence (#{'%013o' % this_chunk_prefix})" \
        unless this_chunk_index==(index+1)
      unless index==chunks.size-1 # Last chunk may be truncated
        stop "!Bad chunk (##{index+1}): Unexpected chunk size (#{'%013o' % this_chunk_prefix})" \
          unless this_chunk_size==chunk_size
      end
      stop "!Bad chunk (##{index+1}): Preamble index not 1 (#{'%013o' % this_preamble_prefix})" \
        unless this_preamble_index==1
      stop "!Bad chunk (##{index+1}): Unexpected preamble length (#{'%013o' % this_preamble_prefix})" \
        unless this_preamble_prefix===first_preamble_prefix
      first_data_word = chunk.at(this_preamble_offset)
      if index > 0
        chunk_words[index].slice!(0,this_preamble_offset)
        stop "!Unexpected result of truncation" unless first_data_word == chunk_words[index].at(0)
      end
    end
    puts "Chunks okay"
    f.data.words = chunk_words.flatten
    f.altered = true # Force f to reload its data
    puts "file size: #{f.data.words.size}"
    hex = f.data.data.to_hex
    puts "nybbles in file: #{hex.size}"
    first_chunk_prefix = f.data.word(0).to_i
    chunk_number = first_chunk_prefix >> 18
    chunk_size = (first_chunk_prefix & 0777777) + 1
    first_preamble_prefix = f.data.word(1).to_i
    puts "chunk_number: #{chunk_number}"
    puts "chunk_size: #{chunk_size}"
    stop "!Bad chunk number: #{chunk_number}" unless chunk_number==1
    stop "!Chunk size is not odd: #{chunk_size}" unless chunk_size.odd?
    f.unpack.write(to)
  end
end