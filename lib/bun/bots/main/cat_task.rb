#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "cat LOCATION", "Copy a file to $stdout"
# TODO Refactor :archive as a global option?
option 'at', :aliases=>'-a', :type=>'string', :desc=>'Archive location'
def cat(location)
  archive = Archive.new(:at=>options[:at])
  archive.open(location) {|f| $stdout.write f.read }
end