#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

no_tasks do
  def push_tbl(tbl, label, value)
    value = value.inspect if !value.is_a?(String) || value.size==0 || value =~ /[[:cntrl:]'"]/
    tbl.push [label, value]
    tbl
  end
end

STANDARD_FIELDS = %w{description catalog_time data data_format digest file_grade file_time
                     identifier owner path shards tape tape_size tape_type }.map{|f| f.to_sym}

SHARDS_ACROSS = 5
desc "describe FILE", "Display description information for a tape"
def describe(file)
  check_for_unknown_options(file)
  # TODO Move logic to File class

  if File.file_grade(file) == :baked
    puts "#{file} is baked. No description available."
    exit
  end

  descriptor    = File.descriptor(file, :graceful=>true)
  type          = descriptor.tape_type
  shards        = descriptor.shards || []
  catalog_time  = descriptor.catalog_time
  
  preamble_table = []
  push_tbl preamble_table, "Tape", descriptor.tape
  push_tbl preamble_table, type==:frozen ? "Directory" : "File", descriptor.path
  push_tbl preamble_table, "Owner", descriptor.owner
  push_tbl preamble_table, "Description", descriptor.description
  push_tbl preamble_table, "Catalog Date", catalog_time.strftime('%Y/%m/%d') if catalog_time
  push_tbl preamble_table, "File Time", descriptor.file_time.strftime(TIME_FORMAT) if type==:frozen
  push_tbl preamble_table, "File Grade", descriptor.file_grade
  push_tbl preamble_table, "Size (Words)", descriptor.tape_size
  push_tbl preamble_table, "Type", type.to_s.sub(/^./) {|c| c.upcase}
  push_tbl preamble_table, "Data Format", descriptor.data_format.to_s.sub(/^./) {|c| c.upcase}
  push_tbl preamble_table, "MD5 Digest", descriptor.digest.scan(/..../).join(' ')
  
  (descriptor.fields.map{|f| f.to_sym} - STANDARD_FIELDS).sort_by{|f| f.to_s }.each do |f|
    push_tbl preamble_table,
             f.to_s.gsub(/_/,' ').gsub(/\b[a-z]/) {|c| c.upcase},
             descriptor[f.to_sym].to_s
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
    titles = ["Name", "Updated At", "Size (Words)"]
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