#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "cat TAPE", "Copy a file to $stdout"
# TODO Refactor :archive as a global option?
option 'archive', :aliases=>'-a', :type=>'string', :desc=>'Archive location'
def cat(tape)
  archive = Archive.new(:location=>options[:archive])
  archive.open(tape) {|f| $stdout.write f.read }
end