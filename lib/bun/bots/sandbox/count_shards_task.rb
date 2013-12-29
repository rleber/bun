#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "count_shards ARCHIVE", "Count shards in frozen files three different ways"
def count_shards(at)
  archive = Archive.new(at)
  table = [%w{Tape Word1 Positions Valid Flag}]
  flagged = false
  archive.each do |tape|
    file = archive.open(tape, :header=>true)
    if file.tape_type == :frozen
      counts = [
        f.shard_count_based_on_word_1, 
        f.shard_count_based_on_position_of_shard_contents, 
        f.shard_count_based_on_count_of_valid_shard_descriptors
      ]
      row = [tape] + counts.map{|c| '%3d' % c } 
      if counts.min != counts.max
        flagged = true
        row << '*'
      else
        row << ''
      end
      table << row
    end
  end
  puts table.justify_rows.map{|row| row.join('  ')}.join("\n")
  stop "!Shard counts don't match in flagged entries" if flagged
end