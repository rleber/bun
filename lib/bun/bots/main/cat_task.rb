#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "cat HOARD", "Copy a hoard to $stdout"
# TODO Refactor :archive as a global option?
option 'at', :aliases=>'-a', :type=>'string', :desc=>'Archive path'
def cat(hoard)
  archive = Archive.new(:at=>options[:at])
  archive.open(hoard) {|f| $stdout.write f.read }
end