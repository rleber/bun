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

RSpec.configure {|c| c.fail_fast = true}

RSpec::Matchers.define :exist_as_a_file do ||
  match do |actual|
    File.exists?(actual)
  end
  failure_message_for_should do |actual|
    "expected that file #{actual} would exist"
  end
end

RSpec::Matchers.define :match_named_pattern do |name, pattern|
  match do |actual|
    actual =~ pattern
  end
  failure_message_for_should do |actual|
    "expected that text would match #{name} pattern: #{pattern.inspect}"
  end
end

# shared_examples "match with variable data" do |fname, patterns|
#   actual_output_file = File.join('output', fname)
#   expected_output_file = File.join('output','test', fname)
#   it "should create the proper file" do
#     file_should_exist actual_output_file
#   end
#   it "should generate output matching each pattern" do
#     actual_output = Bun.readfile(actual_output_file).chomp
#     patterns.each do |key, pat|
#       actual_output.should match_named_pattern(key, pat)
#     end
#   end
#   it "should generate the proper fixed content" do
#     actual_output = Bun.readfile(actual_output_file).chomp
#     expected_output = Bun.readfile(expected_output_file).chomp
#     patterns.each do |key, pat|
#       actual_output = actual_output.sub(pat,'')
#       expected_output = expected_output.sub(pat,'')
#     end
#     actual_output = actual_output.gsub!(/\n+/,"\n").chomp
#     expected_output = expected_output.gsub!(/\n+/,"\n").chomp
#     actual_output.should == expected_output
#   end
# end
RSpec::Matchers.define :match_patterns do |patterns|
  match do |actual|
    patterns.each do |key, pat|
      actual.should match_named_pattern(key, pat)
    end
  end
  failure_message_for_should do |actual|
    "expected that text would match all patterns"
  end
end

RSpec::Matchers.define :match_except_for_patterns do |expected|
  match do |actual|
    actual = actual.dup
    expected = expected.dup
    @patterns.each do |key, pat|
      actual = actual.sub(pat,'')
      expected = expected.sub(pat,'')
    end
    actual = actual.gsub!(/\n+/,"\n").chomp
    expected = expected.gsub!(/\n+/,"\n").chomp
    actual.should == expected
  end
  chain :with_patterns do |patterns|
    @patterns = patterns
  end
  failure_message_for_should do |actual|
    "expected that text would match, except for patterns"
  end
end

RSpec::Matchers.define :match_with_variable_data do |expected|
  match do |actual|
    actual.should match_patterns(@patterns)
    actual.should match_except_for_patterns(expected).with_patterns(@patterns)
  end
  chain :except_for do |patterns|
    @patterns = patterns
  end
  failure_message_for_should do |actual|
    "expected that text would match, with variable data"
  end
end

RSpec::Matchers.define :match_file_with_variable_data do |expected_file|
  match do |actual_file|
    actual_output = Bun.readfile(actual_file).chomp
    expected_output = Bun.readfile(expected_file).chomp
    actual_output.should match_with_variable_data(expected_output).except_for(@patterns)
  end
  chain :except_for do |patterns|
    @patterns = patterns
  end
  failure_message_for_should do |actual_file|
    "expected that content of #{actual_file} would match #{expected_file}, with variable data"
  end
end

ACTUAL_OUTPUT_FILE_PREFIX = File.join('output')
EXPECTED_OUTPUT_FILE_PREFIX = File.join('output', 'test')

RSpec::Matchers.define :match_expected_output_except_for do |patterns|
  match do |file|
    actual_output_file = File.join(ACTUAL_OUTPUT_FILE_PREFIX, file)
    expected_output_file = File.join(EXPECTED_OUTPUT_FILE_PREFIX, file)
    actual_output_file.should match_file_with_variable_data(expected_output_file).except_for(patterns)
  end
  failure_message_for_should do |file|
    "expected that #{file} would match expected output, with variable data"
  end
end

def file_should_exist(name)
  name.should exist_as_a_file
end

def file_should_not_exist(name)
  name.should_not exist_as_a_file
end