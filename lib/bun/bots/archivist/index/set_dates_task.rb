#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "set_dates ARCHIVE", "Set file modification dates for archived files, based on catalog"
option 'dryrun',  :aliases=>'-d', :type=>'boolean', :desc=>"Perform a dry run. Do not actually set dates"
def set_dates(at)
  archive = Archive.new(at)
  shell = Bun::Shell.new(options)
  archive.each do |hoard|
    descr = archive.descriptor(hoard)
    timestamp = descr[:updated]
    if timestamp
      puts "About to set timestamp: #{hoard} #{timestamp.strftime('%Y/%m/%d %H:%M:%S')}" unless options[:quiet]
      shell.set_timestamp(archive.expand_path(hoard), timestamp)
    else
      puts "No updated time available for #{hoard}" unless options[:quiet]
    end
  end
end