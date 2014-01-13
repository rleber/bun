#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "exec [TEST]...", "Run the specified tests"
option 'debug',    :aliases=>'-d', :type=>'boolean', :desc=>"Run tests in debugging mode"
option 'examples', :aliases=>'-e', :type=>'string',  :desc=>"Run test examples matching this string"
option 'params',   :aliases=>'-p', :type=>'string',  :desc=>"Send these params to tests (any Ruby expression)"
def exec(*tests)
  tests = %w{all} if tests.size == 0
  params = {}
  params['BUN_TEST_DEBUG'] = params[:debug] && true
  params['BUN_TEST_PARAMS'] = params[:params]
  Bun::Test.run(*tests, options.merge(params: params))
end