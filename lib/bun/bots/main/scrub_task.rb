#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "scrub FILE", "Clean up backspaces and tabs in a file"
option "tabs", :aliases=>'-t', :type=>'string', :desc=>"Set tab stops"
def scrub(file)
  tabs = options[:tabs] || '80'
  system("cat #{file.inspect} | ruby -p -e '$_.gsub!(/_\\x8/,\"\")' | expand -t #{tabs}")
end