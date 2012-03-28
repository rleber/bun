#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

VALID_MESSAGES = %w{missing name old new old_file new_file}
DATE_FORMAT = '%Y/%m/%d %H:%M:%S'

desc "check", "Check contents of the catalog"
option 'archive', :aliases=>'-a', :type=>'string',  :desc=>'Archive location'
option "build",   :aliases=>"-b", :type=>'boolean', :desc=>"Don't rely on archive index; always build information from source file"
option "include", :aliases=>'-i', :type=>'string',  :desc=>"Include only certain messages. Options include #{VALID_MESSAGES.join(',')}"
option "exclude", :aliases=>'-x', :type=>'string',  :desc=>"Skip certain messages. Options include #{VALID_MESSAGES.join(',')}"
# TODO Reformat this in columns: location shard match loc1 value1 loc2 value2
def check
  archive = Archive.new(options[:archive])
  exclusions = (options[:exclude] || '').split(/\s*[,\s]\s*/).map{|s| s.strip.downcase }
  inclusions = (options[:include] || VALID_MESSAGES.join(',')).split(/\s*[,\s]\s*/).map{|s| s.strip.downcase }
  table = []
  table << %w{Location Shard Message Source\ 1 Value\ 1 Source\ 2 Value\ 2}
  archive.each do |location|
    location_spec = archive.catalog.find {|spec| spec[:location] == location }
    unless location_spec
      table << [location, '', "No entry in index"] if inclusions.include?('missing') && !exclusions.include?('missing')
      next
    end
    file_descriptor = archive.descriptor(location, :build=>options[:build])
    if File.relative_path(location_spec[:file]) != file_descriptor[:path] && inclusions.include?('name') && !exclusions.include?('name')
      table << [location, '', "Names don't match", "Index", location_spec[:file], 'File', file_descriptor[:path]]
    end
    if file_descriptor[:file_type] == :frozen
      index_date = location_spec[:date]
      location_date = file_descriptor[:file_date]
      case index_date <=> location_date
      when -1 
        table << [location, '', "Older date in index", 'Index', index_date.strftime(DATE_FORMAT), 
                                                       'File',  location_date.strftime(DATE_FORMAT)] \
                                                        if inclusions.include?('old') &&!exclusions.include?('old')
      when 1
        table << [location, '', "Newer date in index", 'Index', index_date.strftime(DATE_FORMAT), 
                                                       'File',  location_date.strftime(DATE_FORMAT)] \
                                                        if inclusions.include?('new') &&!exclusions.include?('new')
      end
      file_descriptor[:shard_count].times do |i|
        descriptor = file_descriptor[:shards][i]
        shard_date = descriptor[:shard_date]
        shard = descriptor[:name]
        case index_date <=> shard_date
        when -1 
          table << [location, shard, "Older date in index", 'Index', index_date.strftime(DATE_FORMAT), 
                                                            'Shard', shard_date.strftime(DATE_FORMAT)] \
                                                            if inclusions.include?('old_file') &&!exclusions.include?('old_file')
        when 1
          table << [location, shard, "Newer date in index", 'Index', index_date.strftime(DATE_FORMAT), 
                                                            'Shard', shard_date.strftime(DATE_FORMAT)] \
                                                            if inclusions.include?('new_file') &&!exclusions.include?('new_file')
        end
        case location_date <=> shard_date
        when -1 
          table << [location, shard, "Older date in file", 'File',   location_date.strftime(DATE_FORMAT), 
                                                           'Shard', shard_date.strftime(DATE_FORMAT)] \
                                                           if inclusions.include?('old_file') &&!exclusions.include?('old_file')
        when 1
          table << [location, shard, "Newer date in file", 'File',   location_date.strftime(DATE_FORMAT), 
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