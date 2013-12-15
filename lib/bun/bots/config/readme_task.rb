#!/usr/bin/env ruby
#  -*- encoding: utf-8 -*-

desc "readme", "Display helpful information about configuration"
def readme
  STDOUT.write Bun.readfile("doc/config_readme.md", :encoding=>'us-ascii')
end
