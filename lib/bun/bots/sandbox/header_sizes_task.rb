#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "header_sizes", "Display the length of file headers"
option 'archive', :aliases=>'-a', :type=>'string',                     :desc=>'Archive location'
option "sort",    :aliases=>'-s', :type=>'string', :default=>'header', :desc=>"Sort by what field: preamble or header (size)"
def header_sizes
  directory = options[:archive] || Archive.location
  archive = Archive.new(:location=>directory)
  data = [%w{Tape Preamble Header}]
  sort_column = ['preamble', 'header'].index(options[:sort].downcase)
  stop "!Bad value for --sort option" unless sort_column
  sort_column += 1
  max_header = max_preamble = nil
  min_header = min_preamble = nil
  sum_header = sum_preamble = 0
  n = 0
  archive.each do |tape_name|
    file = archive.open(tape_name)
    preamble_size = file.content_offset
    header_size = file.header_size
    sum_preamble += preamble_size
    sum_header += header_size
    if !min_preamble || preamble_size < min_preamble
      min_preamble = preamble_size
    end
    if !max_preamble || preamble_size > max_preamble
      max_preamble = preamble_size
    end
    if !min_header || header_size < min_header
      min_header = header_size
    end
    if !max_header || header_size > max_header
      max_header = header_size
    end
    data << [tape_name, preamble_size, header_size]
    n += 1
  end
  data = data.sort_by{|row| row[sort_column].to_i }
  data = data.map{|row| row[-2] = row[-2].to_s; row[-1] = row[-1].to_s; row}
  data << ["Minimum", min_preamble.to_s, min_header.to_s]
  data << ["Average", '%0.1f' % (sum_preamble/n.to_f), '%0.1f' % (sum_header/n.to_f)]
  data << ["Maximum", max_preamble.to_s, max_header.to_s]
  puts data.justify_rows.map{|row| row.join('  ')}.join("\n")
end