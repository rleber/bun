#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "cat TAPE", "Copy a tape to $stdout"
# TODO Refactor :archive as a global option?
def cat(at, tape)
  archive = Archive.new(at)
  archive.open(tape) {|f| $stdout.write f.read }
end