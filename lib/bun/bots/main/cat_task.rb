#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "cat LOCATION", "Copy a file to $stdout"
# TODO Refactor :archive as a global option?
option 'archive', :aliases=>'-a', :type=>'string', :desc=>'Archive location'
def cat(location)
  archive = Archive.new(:at=>options[:archive])
  archive.open(location) {|f| $stdout.write f.read }
end