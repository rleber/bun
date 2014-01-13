#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "compare_offsets ARCHIVE", "Compare file offsets vs. content of file preamble"
def compare_offsets(at)
  check_for_unknown_options(at)
  archive = Archive.new(at)
  table = [%w{Tape Word1 Calculated Flag}]
  flagged = false
  archive.each do |tape|
    file = archive.open(tape)
    counts = [
      file.words.at(1).half_words.at(1).to_i, 
      file.content_offset
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
  puts table.justify_rows.map{|row| row.join('  ')}.join("\n")
  stop "!Offsets don't match in flagged entries" if flagged
end