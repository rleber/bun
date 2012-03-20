#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

require File.join(File.dirname(__FILE__), '../lib/bun')
require File.join(File.dirname(__FILE__), '../lib/slicr')
require File.join(File.dirname(__FILE__), '../lib/indexable_basic')
require File.join(File.dirname(__FILE__), '../lib/bun')
require File.join(File.dirname(__FILE__), 'slices.rb')
require 'rspec/expectations'

# Usage capture :stdout, :stderr { foo } => <contents of all streams>
def capture(*streams)
  streams.map! { |stream| stream.to_s }
  begin
    result = StringIO.new
    streams.each { |stream| eval "$#{stream} = result" }
    yield
  ensure
    streams.each { |stream| eval("$#{stream} = #{stream.upcase}") }
  end
  result.to_s
end

RSpec::Matchers.define :exist_as_a_file do ||
  match do |actual|
    File.exists?(actual)
  end
  failure_message_for_should do |actual|
    "expected that file #{actual} would exist"
  end
end

def file_should_exist(name)
  name.should exist_as_a_file
end

def file_should_not_exist(name)
  name.should_not exist_as_a_file
end