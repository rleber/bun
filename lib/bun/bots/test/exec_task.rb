#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "exec", "Test this software"
def exec
  Kernel.exec "thor spec"
end