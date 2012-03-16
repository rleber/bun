SHARDS_ACROSS = 5
desc "describe TAPE", "Display description information for a file"
option 'archive', :aliases=>'-a', :type=>'string', :desc=>'Archive location'
option "build",   :aliases=>"-b", :type=>'boolean',                              :desc=>"Don't rely on archive index; always build information from source file"
def describe(file_name)
  directory = options[:archive] || Archive.location
  archive = Archive.new(directory)
  descriptor    = archive.descriptor(file_name, :build=>options[:build])
  type          = descriptor.file_type
  shards        = descriptor.shard_names
  index_date    = descriptor.index_date
  index_date_display = index_date ? index_date.strftime('%Y/%m/%d') : "n/a"
  
  # TODO Refactor using Array#justify_rows
  puts "Tape:            #{descriptor.tape_name}"
  puts "Tape path:       #{descriptor.tape_path}"
  puts "Archived file:   #{descriptor.path}"
  puts "Owner:           #{descriptor.owner}"
  puts "Subdirectory:    #{descriptor.subdirectory}"
  puts "Name:            #{descriptor.name}"
  puts "Description:     #{descriptor.description}"
  puts "Specification:   #{descriptor.specification}"
  puts "Index date:      #{index_date_display}"
  if type == :frozen
    puts "File date:       #{descriptor.file_time.strftime(TIME_FORMAT)}"
    puts "Updated at:      #{descriptor.updated.strftime(TIME_FORMAT)}"
  end
  puts "Size (words):    #{descriptor.file_size}"
  puts "Type:            #{type.to_s.sub(/^./) {|m| m.upcase}}"

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
          column = [shards[i], shard[:path], shard[:file_time].strftime(TIME_FORMAT), shard[:file_size]]
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
