#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "readme", "Display helpful information for beginners"
def readme
  STDOUT.write Bun.readfile("doc/readme.md", :encoding=>'us-ascii')
end