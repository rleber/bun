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
  sio = StringIO.new
  begin
    streams.each { |stream| eval "$#{stream} = sio" }
    yield
  ensure
    streams.each { |stream| eval("$#{stream} = #{stream.upcase}") }
  end
  sio.string
end

def debug?
  ENV['BUN_TEST_DEBUG']
end

def params
  $params ||= eval(ENV['BUN_TEST_PARAMS'])
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
    msg = "text does not match #{name} pattern"
    $msg ||= []
    $msg << msg
    msg
  end
end

# Match text to each of a set of specified patterns (in a Hash)
#  expected_patterns = {pat1: /a*/, pat2: /b*/, pat3: /c*/}
#  "aaaaxbbycccz".should match_patterns(expected_patterns)
#  Note that each specified pattern must match at least once in the actual string
RSpec::Matchers.define :match_patterns do |patterns|
  match do |actual|
    patterns.each do |key, pat|
      actual.should match_named_pattern(key, pat)
    end
  end
  failure_message_for_should do |actual|
    "text did not match all patterns: #{$msg.join(', ')}"
  end
end

# Match text, except for specified patterns (in a Hash)
#  excluded_patterns = {pat1: /a+/, pat2: /b+/, pat3: /c+/}
#  "aaaaxbbycccz".should match_except_for_patterns("xyz").with_patterns(excluded_patterns)
#  Note that specified patterns need not match in either actual or expected strings
RSpec::Matchers.define :match_except_for_patterns do |expected|
  match do |actual|
    actual_text = actual.dup
    expected_text = expected.dup
    @patterns.each do |key, pat|
      actual_text = actual_text.sub(pat,'')
      expected_text = expected_text.sub(pat,'')
    end
    actual_text = actual_text.sub(/\n+\Z/,'')
    expected_text = expected_text.sub(/\n+\Z/,'')
    actual_text.should == expected_text
  end
  chain :with_patterns do |patterns|
    @patterns = patterns
  end
  failure_message_for_should do |actual|
    msg = "non-variable text should match"
    $msg ||= []
    $msg << msg
    msg
  end
end

# Match text, except for specified patterns (in a Hash)
#  excluded_patterns = {pat1: /a*/, pat2: /b*/, pat3: /c*/}
#  "aaaaxbbycccz".should match_with_variable_data("axbycz").except_for(excluded_patterns)
#  Note that specified patterns must match at least once in both actual and expected strings
RSpec::Matchers.define :match_with_variable_data do |expected|
  match do |actual|
    actual.should match_patterns(@patterns)
    actual.should match_except_for_patterns(expected).with_patterns(@patterns)
  end
  chain :except_for do |patterns|
    @patterns = patterns
  end
  failure_message_for_should do |actual|
    "text with variable data did not match: #{$msg.join(', ')}"
  end
end

# Content of two files should match, except for excluded patterns
#  excluded_patterns = {pat1: /a*/, pat2: /def/, pat3: /ghi/}
#  "data/actual.txt".should
#      match_file_with_variable_data("data/expected.txt").except_for(excluded_patterns)
#  # Assuming data/actual.txt contains "aaaaxbbycccz"
#  # and data/expected.txt contains "axbycz"
RSpec::Matchers.define :match_file_with_variable_data do |expected_file|
  match do |actual_file|
    Bun::Test.save_actual_output(actual_file)
    actual_output = Bun.readfile(actual_file).chomp
    expected_output = Bun.readfile(expected_file).chomp
    actual_output.should match_with_variable_data(expected_output).except_for(@patterns)
  end
  chain :except_for do |patterns|
    @patterns = patterns
  end
  failure_message_for_should do |actual_file|
    "content of #{actual_file} did not match #{expected_file}: #{$msg.join(', ')}"
  end
end

ACTUAL_OUTPUT_FILE_PREFIX = File.join('output', 'test_actual')
EXPECTED_OUTPUT_FILE_PREFIX = File.join('output', 'test_expected')

# Content of two files with (matching names) should match, except for excluded patterns
#  excluded_patterns = {pat1: /a*/, pat2: /def/, pat3: /ghi/}
#  "actual.txt".should match_expected_output_except_for(excluded_patterns)
#  # Assuming output/actual.txt contains "aaaaxbbycccz"
#  #      and output/test/expected.txt contains "axbycz"
RSpec::Matchers.define :match_expected_output_except_for do |patterns|
  match do |file|
    actual_output_file = File.join(ACTUAL_OUTPUT_FILE_PREFIX, file)
    expected_output_file = File.join(EXPECTED_OUTPUT_FILE_PREFIX, file)
    actual_output_file.should match_file_with_variable_data(expected_output_file).except_for(patterns)
  end
  failure_message_for_should do |file|
    "#{file} did not match expectations: #{$msg.join(', ')}"
  end
end

# Content of two files should match
RSpec::Matchers.define :match_file do |expected_file|
  match do |file|
    Bun::Test.save_actual_output(file)
    actual_output = Bun.readfile(file).chomp
    expected_output = Bun.readfile(expected_file).chomp
    actual_output.should == expected_output
  end
  failure_message_for_should do |file|
    "#{file} did not match expectations in #{expected_file}"
  end
end

# Content of two files with (matching names) should match
RSpec::Matchers.define :match_expected_output do
  match do |file|
    actual_output_file = File.join(ACTUAL_OUTPUT_FILE_PREFIX, file)
    expected_output_file = File.join(EXPECTED_OUTPUT_FILE_PREFIX, file)
    actual_output_file.should match_file(expected_output_file)
  end
  failure_message_for_should do |file|
    "#{file} did not match expectations"
  end
end

# File contents should match a string
RSpec::Matchers.define :contain_content do |expected_content|
  match do |file|
    Bun::Test.save_actual_output(file)
    actual_output = Bun.readfile(file).chomp
    actual_output.should == expected_content
  end
  failure_message_for_should do |file|
    "#{file} did not contain expected content (#{expected_content.inspect}"
  end
end


# File contents should be empty
RSpec::Matchers.define :be_an_empty_file do 
  match do |file|
    file.should contain_content("")
  end
  failure_message_for_should do |file|
    "#{file} was not empty"
  end
end

def file_should_exist(name)
  name.should exist_as_a_file
end

def file_should_not_exist(name)
  name.should_not exist_as_a_file
end