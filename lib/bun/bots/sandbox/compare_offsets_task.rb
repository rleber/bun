#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "compare_offsets", "Compare file offsets vs. content of file preamble"
option 'at', :aliases=>'-a', :type=>'string', :desc=>'Archive path'
def compare_offsets
  archive = Archive.new(:at=>options[:at])
  table = [%w{Hoard Word1 Calculated Flag}]
  flagged = false
  archive.each do |hoard|
    file = archive.open(hoard)
    counts = [
      file.words.at(1).half_words.at(1).to_i, 
      file.content_offset
    ]
    row = [hoard] + counts.map{|c| '%3d' % c } 
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