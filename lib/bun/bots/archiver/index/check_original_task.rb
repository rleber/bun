VALID_MESSAGES = %w{missing name old new old_file new_file}
DATE_FORMAT = '%Y/%m/%d %H:%M:%S'
# TODO Create check method: Check that an index file entry exists for each tape
# file, check frozen file dates and content vs. index, check 
# text archive file contents vs. index
desc "check_catalog", "Check contents of the catalog"
option 'archive', :aliases=>'-a', :type=>'string',  :desc=>'Archive location'
option "build",   :aliases=>"-b", :type=>'boolean', :desc=>"Don't rely on archive index; always build information from source file"
option "include", :aliases=>'-i', :type=>'string',  :desc=>"Include only certain messages. Options include #{VALID_MESSAGES.join(',')}"
option "exclude", :aliases=>'-x', :type=>'string',  :desc=>"Skip certain messages. Options include #{VALID_MESSAGES.join(',')}"
# TODO Reformat this in columns: tape shard match loc1 value1 loc2 value2
def check_catalog
  archive = Archive.new(options[:archive])
  exclusions = (options[:exclude] || '').split(/\s*[,\s]\s*/).map{|s| s.strip.downcase }
  inclusions = (options[:include] || VALID_MESSAGES.join(',')).split(/\s*[,\s]\s*/).map{|s| s.strip.downcase }
  table = []
  table << %w{Tape Shard Message Source\ 1 Value\ 1 Source\ 2 Value\ 2}
  archive.each do |tape|
    tape_spec = archive.catalog.find {|spec| spec[:tape] == tape }
    unless tape_spec
      table << [tape, '', "No entry in index"] if inclusions.include?('missing') && !exclusions.include?('missing')
      next
    end
    file_descriptor = archive.descriptor(tape, :build=>options[:build])
    if File.relative_path(tape_spec[:file]) != file_descriptor[:path] && inclusions.include?('name') && !exclusions.include?('name')
      table << [tape, '', "Names don't match", "Index", tape_spec[:file], 'File', file_descriptor[:path]]
    end
    if file_descriptor[:file_type] == :frozen
      index_date = tape_spec[:date]
      tape_date = file_descriptor[:file_date]
      case index_date <=> tape_date
      when -1 
        table << [tape, '', "Older date in index", 'Index', index_date.strftime(DATE_FORMAT), 
                                                   'File',  tape_date.strftime(DATE_FORMAT)] \
                                                        if inclusions.include?('old') &&!exclusions.include?('old')
      when 1
        table << [tape, '', "Newer date in index", 'Index', index_date.strftime(DATE_FORMAT), 
                                                   'File',  tape_date.strftime(DATE_FORMAT)] \
                                                        if inclusions.include?('new') &&!exclusions.include?('new')
      end
      file_descriptor[:shard_count].times do |i|
        descriptor = file_descriptor[:shards][i]
        shard_date = descriptor[:shard_date]
        shard = descriptor[:name]
        case index_date <=> shard_date
        when -1 
          table << [tape, shard, "Older date in index", 'Index', index_date.strftime(DATE_FORMAT), 
                                                        'Shard', shard_date.strftime(DATE_FORMAT)] \
                                                          if inclusions.include?('old_file') &&!exclusions.include?('old_file')
        when 1
          table << [tape, shard, "Newer date in index", 'Index', index_date.strftime(DATE_FORMAT), 
                                                        'Shard', shard_date.strftime(DATE_FORMAT)] \
                                                          if inclusions.include?('new_file') &&!exclusions.include?('new_file')
        end
        case tape_date <=> shard_date
        when -1 
          table << [tape, shard, "Older date in file", 'File',   tape_date.strftime(DATE_FORMAT), 
                                                        'Shard', shard_date.strftime(DATE_FORMAT)] \
                                                          if inclusions.include?('old_file') &&!exclusions.include?('old_file')
        when 1
          table << [tape, shard, "Newer date in file", 'File',   tape_date.strftime(DATE_FORMAT), 
                                                        'Shard', shard_date.strftime(DATE_FORMAT)] \
                                                          if inclusions.include?('new_file') &&!exclusions.include?('new_file')
        end
      end
    end
  end
  if table.size <= 1
    puts "No messages"
  else
    puts table.justify_rows.map{|row| row.join('  ')}.join("\n")
  end
end
