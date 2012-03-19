#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

desc "cat TAPE", "Copy a file to $stdout"
# TODO Refactor :archive as a global option?
option 'archive', :aliases=>'-a', :type=>'string', :desc=>'Archive location'
def cat(tape)
  directory = options[:archive] || Archive.location
  archive = Archive.new(directory)
  archive.open(tape) {|f| $stdout.write f.read }
end