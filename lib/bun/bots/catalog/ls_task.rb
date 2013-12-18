#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "ls", "List the catalog file for the archive"
option 'at', :aliases=>'-a', :type=>'string', :desc=>'Archive path'
def ls
  archive = Archive.new(:at=>options[:at])
  puts "Hoard       Update      File/Directory"
  archive.catalog.each do |spec|
    puts "#{spec[:hoard]}  #{spec[:date].strftime('%Y/%d/%m')}  #{spec[:file]}"
  end
end