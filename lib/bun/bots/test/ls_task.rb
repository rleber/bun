#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "ls", "List the available tests"
def ls
  puts Bun::Test.all_tests
end