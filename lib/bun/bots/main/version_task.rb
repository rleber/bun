#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "version", "Display software version"
def version
  puts Bun.expanded_version
end