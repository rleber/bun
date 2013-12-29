#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

STANDARD_FIELDS = %w{tape path owner description catalog_time 
                     file_time tape_size tape_type data_format shards}.map{|f| f.to_sym}

SHARDS_ACROSS = 5
desc "describe FILE", "Display description information for a tape"
def describe(file)
  descriptor    = File.descriptor(file, :graceful=>true)
  type          = descriptor.tape_type
  shards        = descriptor.shards || []
  catalog_time    = descriptor.catalog_time
  
  preamble_table = []
  preamble_table.push ["Tape", descriptor.tape]
  preamble_table.push [type==:frozen ? "Directory" : "File", descriptor.path]
  preamble_table.push ["Owner", descriptor.owner]
  preamble_table.push ["Description", descriptor.description]
  preamble_table.push ["Catalog date", catalog_time.strftime('%Y/%m/%d')] if catalog_time
  preamble_table.push ["File time", descriptor.file_time.strftime(TIME_FORMAT)] if type==:frozen
  preamble_table.push ["Size (words)", descriptor.tape_size]
  preamble_table.push ["Type", type.to_s.sub(/^./) {|c| c.upcase}]
  preamble_table.push ["Data Format", descriptor.data_format.to_s.sub(/^./) {|c| c.upcase}]

  (descriptor.fields - STANDARD_FIELDS).sort_by{|f| f.to_s }.each do |f|
    preamble_table.push [
                          f.to_s.gsub(/_/,' ').gsub(/\b[a-z]/) {|c| c.upcase},
                          descriptor[f.to_sym].to_s
                        ]
  end
  
  puts preamble_table.justify_rows.map {|row| row.join('  ')}

  if shards.size > 0
    # Display shard information in a table, SHARDS_ACROSS shards per row,
    # Multiple rows of information for each shard
    # TODO Modify Array extensions and refactor
    puts
    puts "Shards"
    grand_table = []
    columns = 0
    titles = ["Name", "Updated at", "Size (words)"]
    i = 0
    loop do
      break if i >= shards.size
      table = [titles]
      SHARDS_ACROSS.times do |j|
        if i >= shards.size
          column = [""]*(titles.size)
        else
          shard = descriptor[:shards][i]
          column = [shard[:name], shard[:file_time].strftime(TIME_FORMAT), shard[:size]]
        end
        table << column
        i += 1
      end
      table.each_with_index do |column, j|
        if grand_table[j]
          grand_table[j] << ''
          grand_table[j] += column
        else
          grand_table[j] = column.dup
        end
      end
    end
    row_table = grand_table.justify_columns.transpose
    puts row_table.map{|row| '  ' + row.join('  ')}.join("\n")
  end
end