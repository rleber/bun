#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

require 'lib/bun/bots/test/base.rb'

desc "ls", "List the available tests"
def ls
  puts Bun::Test.all_tests
end