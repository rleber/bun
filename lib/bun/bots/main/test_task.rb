#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

desc "test", "test this software"
def test
  exec "thor spec"
end