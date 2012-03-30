#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "ls", "List the catalog file for the archive"
option 'archive', :aliases=>'-a', :type=>'string', :desc=>'Archive location'
def ls
  archive = Archive.new(:location=>options[:archive])
  puts "Location    Update      File/Directory"
  archive.catalog.each do |spec|
    puts "#{spec[:location]}  #{spec[:date].strftime('%Y/%d/%m')}  #{spec[:file]}"
  end
end