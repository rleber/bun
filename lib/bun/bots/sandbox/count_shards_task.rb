#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "count_shards", "Count shards in frozen files three different ways"
option 'archive', :aliases=>'-a', :type=>'string', :desc=>'Archive location'
def count_shards
  directory = options[:archive] || Archive.location
  archive = Archive.new(directory)
  table = [%w{Tape Word1 Positions Valid Flag}]
  flagged = false
  archive.each do |tape_name|
    file = archive.open(tape_name, :header=>true)
    if file.file_type == :frozen
      counts = [
        f.shard_count_based_on_word_1, 
        f.shard_count_based_on_position_of_shard_contents, 
        f.shard_count_based_on_count_of_valid_shard_descriptors
      ]
      row = [tape_name] + counts.map{|c| '%3d' % c } 
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