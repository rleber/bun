#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

require 'lib/bun/bots/test/base.rb'

desc "exec [TEST]...", "Run the specified tests"
def exec(*tests)
  tests = %w{all} if tests.size == 0
  Bun::Test.run(*tests)
end