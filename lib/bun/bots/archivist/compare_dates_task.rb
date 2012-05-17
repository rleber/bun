#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

require 'pp'
require 'lib/array'

desc "compare_dates", "Compare update dates for matching files"
option 'at',      :aliases=>'-a', :type=>'string',  :desc=>'Archive location'
option "build",   :aliases=>"-b", :type=>'boolean', :desc=>"Don't rely on at index; always build information from source file"
option 'type',    :aliases=>'-t', :type=>'string',  :desc=>'Select file type (or all)', :default=>'all'
def compare_dates
  archive = Archive.new(:at=>options[:at])
  file_update_dates = {}
  file_types = if %w{* all}.include?(options[:type])
                 [:text, :frozen, :huffman]
               else
                 options[:type].split(',').map(&:to_sym)
               end
  archive.each do |location|
    descriptor = archive.descriptor(location, :build=>options[:build])
    next unless file_types.include?(descriptor.file_type)
    path = descriptor.path
    file_update_dates[path] ||= []
    file_update_dates[path] << {
      location: location, 
      date_string: (descriptor.updated ? descriptor.updated.strftime('%Y/%m/%d %H:%M:%S') : 'n/a').sub(/\s+00:00:00$/,''),
      descriptor: descriptor
    }
  end
  file_update_dates.keys.sort.each do |path|
    next unless file_update_dates[path].size > 1
    puts path + ':'
    columns = []
    file_update_dates[path].sort_by{|d| d[:date_string]}.each do |entry|
      new_column = [entry[:location], entry[:date_string]]
      new_column += [''] + entry[:descriptor].shards.map{|s| s.name}.sort if entry[:descriptor].file_type == :frozen
      columns << new_column
    end
    cols = ([['  ']*columns.first.size] + columns)
    rows = cols.normalized_transpose
    puts rows.justify_rows.map{|row| row.join('  ')}
    puts
  end
end