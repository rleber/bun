#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

require 'pp'
require 'lib/array'

desc "compare_dates ARCHIVE", "Compare update dates for matching files"
option "build",   :aliases=>"-b", :type=>'boolean', :desc=>"Don't rely on at index; always build information from source file"
option 'type',    :aliases=>'-t', :type=>'string',  :desc=>'Select file type (or all)', :default=>'all'
def compare_dates(at)
  check_for_unknown_options(at)
  archive = Archive.new(at)
  file_update_dates = {}
  tape_types = if %w{* all}.include?(options[:type])
                 [:text, :frozen, :huffman]
               else
                 options[:type].split(',').map(&:to_sym)
               end
  archive.each do |tape|
    descriptor = archive.descriptor(tape, :build=>options[:build])
    next unless tape_types.include?(descriptor.tape_type)
    path = descriptor.path
    file_update_dates[path] ||= []
    file_update_dates[path] << {
      tape: tape, 
      date_string: (descriptor.updated ? descriptor.updated.strftime('%Y/%m/%d %H:%M:%S') : 'n/a').sub(/\s+00:00:00$/,''),
      descriptor: descriptor
    }
  end
  file_update_dates.keys.sort.each do |path|
    next unless file_update_dates[path].size > 1
    puts path + ':'
    columns = []
    file_update_dates[path].sort_by{|d| d[:date_string]}.each do |entry|
      new_column = [entry[:tape], entry[:date_string]]
      new_column += [''] + entry[:descriptor].shards.map{|s| s.name}.sort if entry[:descriptor].tape_type == :frozen
      columns << new_column
    end
    cols = ([['  ']*columns.first.size] + columns)
    rows = cols.normalized_transpose
    puts rows.justify_rows.map{|row| row.join('  ')}
    puts
  end
end