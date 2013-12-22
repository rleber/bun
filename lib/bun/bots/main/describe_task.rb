#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

SHARDS_ACROSS = 5
desc "describe ARCHIVE TAPE", "Display description information for a tape"
option "build",   :aliases=>"-b", :type=>'boolean', :desc=>"Don't rely on at index; always build information from source file"
def describe(at, file_name)
  archive = Archive.new(at, options)
  descriptor    = archive.descriptor(file_name, :build=>options[:build])
  abort "File #{file_name} is not in the archive" unless descriptor
  type          = descriptor.file_type
  shards        = descriptor.shards || []
  catalog_time    = descriptor.catalog_time
  catalog_time_display = catalog_time ? catalog_time.strftime('%Y/%m/%d') : "n/a"
  
  # TODO Refactor using Array#justify_rows
  puts "Tape:         #{descriptor.tape}"
  puts "Path:          #{descriptor.tape_path}"
  if type == :frozen
    puts "Directory:     #{descriptor.path}"
  else
    puts "File:          #{descriptor.path}"
  end
  puts "Owner:         #{descriptor.owner}"
  puts "Subdirectory:  #{descriptor.subdirectory}"
  puts "Basename:      #{descriptor.basename}"
  puts "Description:   #{descriptor.description}"
  puts "Specification: #{descriptor.specification}"
  puts "Catalog date:  #{catalog_time_display}"
  if type == :frozen
    puts "File time:     #{descriptor.file_time.strftime(TIME_FORMAT)}"
    puts "Updated at:    #{descriptor.updated.strftime(TIME_FORMAT)}"
  end
  puts "Size (words):  #{descriptor.file_size}"
  puts "Type:          #{type.to_s.sub(/^./) {|m| m.upcase}}"

  if shards.size > 0
    # Display shard information in a table, SHARDS_ACROSS shards per row,
    # Multiple rows of information for each shard
    # TODO Modify Array extensions and refactor
    puts
    puts "Shards:"
    grand_table = []
    columns = 0
    titles = %w{Name: Path: Updated\ at: Size\ (words):}
    i = 0
    loop do
      break if i >= shards.size
      table = [titles]
      SHARDS_ACROSS.times do |j|
        if i >= shards.size
          column = [""]*4
        else
          shard = descriptor[:shards][i]
          column = [shard[:name], shard[:path], shard[:file_time].strftime(TIME_FORMAT), shard[:file_size]]
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