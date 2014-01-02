#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

require 'lib/bun/bots/test/base.rb'

desc "exec [TEST]...", "Run the specified tests"
option 'debug', :aliases=>'-d', :type=>'boolean', :desc=>"Run tests in debugging mode"
def exec(*tests)
  tests = %w{all} if tests.size == 0
  Bun::Test.run(*tests, 'DEBUG'=>options[:debug] && 'true')
end