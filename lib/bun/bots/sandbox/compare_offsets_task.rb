#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "compare_offsets", "Compare file offsets vs. content of file preamble"
option 'archive', :aliases=>'-a', :type=>'string', :desc=>'Archive location'
def compare_offsets
  archive = Archive.new(:at=>options[:archive])
  table = [%w{Location Word1 Calculated Flag}]
  flagged = false
  archive.each do |location|
    file = archive.open(location)
    counts = [
      file.words.at(1).half_words.at(1).to_i, 
      file.content_offset
    ]
    row = [location] + counts.map{|c| '%3d' % c } 
    if counts.min != counts.max
      flagged = true
      row << '*'
    else
      row << ''
    end
    table << row
  end
  puts table.justify_rows.map{|row| row.join('  ')}.join("\n")
  stop "!Offsets don't match in flagged entries" if flagged
end