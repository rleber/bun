#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

require 'pp'
require 'lib/array'

desc "check_frozen_file_dates", "List update dates for frozen_files"
option 'at',      :aliases=>'-a', :type=>'string',  :desc=>'Archive location'
option "build",   :aliases=>"-b", :type=>'boolean', :desc=>"Don't rely on at index; always build information from source file"
def check_frozen_file_dates
  archive = Archive.new(:at=>options[:at])
  file_update_dates = {}
  archive.each do |location|
    descriptor = archive.descriptor(location, :build=>options[:build])
    next unless descriptor.file_type == :frozen
    path = descriptor.path
    file_update_dates[path] ||= []
    file_update_dates[path] << {
      location: location, 
      date_string: descriptor.updated ? descriptor.updated.strftime('%Y/%m/%d %H:%M:%S') : 'n/a',
      descriptor: descriptor
    }
  end
  file_update_dates.keys.sort.each do |path|
    next unless file_update_dates[path].size > 1
    puts path + ':'
    columns = []
    file_update_dates[path].sort_by{|d| d[:date_string]}.each do |entry|
      columns << [entry[:location], entry[:date_string],''] + entry[:descriptor].shards.map{|s| s.name}.sort
    end
    cols = ([['  ']*columns.first.size] + columns)
    rows = cols.normalized_transpose
    puts rows.justify_rows.map{|row| row.join('  ')}
    puts
  end
end