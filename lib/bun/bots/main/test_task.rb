#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "test", "test this software"
def test
  exec "thor spec"
end