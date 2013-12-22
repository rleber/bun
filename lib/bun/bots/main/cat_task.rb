#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "cat HOARD", "Copy a hoard to $stdout"
# TODO Refactor :archive as a global option?
def cat(at, hoard)
  archive = Archive.new(at)
  archive.open(hoard) {|f| $stdout.write f.read }
end