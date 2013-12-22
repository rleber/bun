#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "ls ARCHIVE", "List the catalog file for the archive"
def ls(at)
  archive = Archive.new(at)
  puts "Tape       Update      File/Directory"
  archive.catalog.each do |spec|
    puts "#{spec[:tape]}  #{spec[:date].strftime('%Y/%d/%m')}  #{spec[:file]}"
  end
end