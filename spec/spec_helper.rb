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

def captured
  stdout_text = capture(:stdout) do
    stderr_text = capture(:stderr) do
      yield
    end
  end
  [stdout_text, stderr_text]
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

require 'tempfile'
require 'shellwords'
require 'yaml'

TEST_ARCHIVE = File.join(File.dirname(__FILE__),'..','data','test', 'archive', 'general_test')

$saved_commands = []

def save(cmd)
  $saved_commands << cmd
  cmd
end

def saved_commands
  $saved_commands
end

def exec(cmd, options={})
  save(cmd)
  # if cmd =~ /bun\s+roff.*creates_blank_space_on_the_next_page/
  #   STDERR.puts cmd
  #   words = cmd.split(/\s+/)
  #   cp_command = "cp #{words[2]} ~/.roff_test"
  #   STDERR.puts cp_command
  #   system(cp_command)
  #   revised_command = cmd.sub(/\s+>.*/,'')
  #   STDERR.puts revised_command
  #   system(revised_command)
  #   exit
  # else
    res = `#{cmd}`
  # end
  unless $?.exitstatus == 0
    allowed_codes = [options[:allowed] || []].flatten
    unless allowed_codes.include?(:all)
      unless allowed_codes.include?($?.exitstatus)
        STDERR.puts "Output from failed command:"
        STDERR.puts res      
        raise RuntimeError, "Command #{cmd} failed with exit status #{$?.exitstatus}"
      end
    end
  end
  res
end

$backtrace = 5

def backtrace(options={})
  if $backtrace && failure?
    if $saved_commands && $saved_commands.size > 0
      ::File.open(Bun::Test::BACKTRACE_FILE, 'w') {|f| f.write($saved_commands.join("\n")) }
      unless options[:quiet]
        $stderr.puts "Command backtrace:"
        system("bun test trace -i 2 #{$backtrace}")
      end
    end
  else
    `rm -f #{Bun::Test::BACKTRACE_FILE}`
  end
end

def success?
  examples = RSpec.world.filtered_examples.values.flatten
  examples.none?(&:exception)
end

def failure?
  !success?
end

def exec_on_success(cmd, options={})
  return unless success?
  exec cmd, options
end

def exec_on_failure(cmd, options={})
  return if success?
  exec cmd, options
end

def decode(file_name)
  archive = Bun::Archive.new(TEST_ARCHIVE)
  expanded_file = File.join("data", "test", file_name)
  file = Bun::File::Text.open(expanded_file)
  file.text
end

def scrub(lines, options={})
  tabs = options[:tabs] || '80'
  tempfile = Tempfile.new('bun1')
  tempfile2 = Tempfile.new('bun2')
  tempfile.write(lines)
  tempfile.close
  tempfile2.close
  system([
            "cat #{tempfile.path.inspect}",
            "ruby -p -e '$_.gsub!(/_\\x8/,\"\")'",
            "expand -t #{tabs} >#{tempfile2.path.inspect}"
          ].join(' | '))
  rstrip(Bun.readfile(tempfile2.path))
end

def decode_and_scrub(file, options={})
  scrub(decode(file), options)
end

def rstrip(text)
  text.split("\n").map{|line| line.rstrip }.join("\n")
end

shared_examples "simple" do |source|
  it "decodes a simple text file (#{source})" do
    source_file = source + Bun::DEFAULT_UNPACKED_FILE_EXTENSION
    expected_output_file = File.join("output", "test_expected", source)
    actual_output = decode(source_file)
    expected_output = Bun.readfile(expected_output_file)
    actual_output.should == expected_output
  end
end

shared_examples "command" do |descr, command, expected_stdout_file, options={}|
  it "handles #{descr} properly" do
    # warn "> bun #{command}"
    res = exec("bun #{command} 2>&1", options).force_encoding('ascii-8bit')
    expected_stdout_file = File.join("output", "test_expected", expected_stdout_file) \
        unless expected_stdout_file =~ %r{/}
    raise "!Missing expected output file: #{expected_stdout_file.inspect}" \
        unless File.exists?(expected_stdout_file)  
    rstrip(res).should == rstrip(Bun.readfile(expected_stdout_file))
  end
end

shared_examples "command from STDIN" do |descr, command, input_file, expected_stdout_file, options={}|
  it "handles #{descr} from STDIN properly" do
    # warn "> bun #{command}"
    res = exec("cat #{input_file} | bun #{command} 2>&1", options).force_encoding('ascii-8bit')
    expected_stdout_file = File.join("output", 'test_expected', expected_stdout_file) \
        unless expected_stdout_file =~ %r{/}
    raise "!Missing expected output file: #{expected_stdout_file.inspect}" \
        unless File.exists?(expected_stdout_file)  
    rstrip(res).should == rstrip(Bun.readfile(expected_stdout_file))
  end
end

def exec_test(descr, command, prefix, options={})
  context descr do
    before :all do
      @output_basename = (prefix + "_" + descr).gsub(/\W/,'_').gsub(/_+/,'_')
      @actual_output_file = File.join('output', 'test_actual', @output_basename)
      @expected_output_file = File.join('output', 'test_expected', @output_basename)
      @allowed_codes = options[:allowed] || [0]
      @allowed_codes << 1 if options[:fail]
      exec("rm -rf #{@actual_output_file}")
      exec_command = "bun #{command} >#{@actual_output_file}"
      exec_command += " 2>&1" unless options[:trap_stderr]==false
      exec(exec_command, allowed: @allowed_codes)
    end
    if options[:fail]
      it "should fail" do
        $?.exitstatus.should == 1
      end
    end
    it "should generate the expected output" do
      @output_basename.should match_expected_output
    end
    after :all do 
      backtrace
      exec_on_success("rm -rf #{@actual_output_file}")
    end
    end
end

def exec_test_hash(prefix, test)
  exec_test(
    test[:title], 
    test[:command], 
    prefix, 
    allowed: test[:allowed]||[0],
    fail: test[:fail],
    trap_stderr: test[:trap_stderr]!=false
  )
end

shared_examples "command with file" do |descr, command, expected_stdout_file, output_file, expected_output_file|
  context descr do
    before :all do
      # warn "> bun #{command}"
      @res = exec("bun #{command} 2>&1")
      @expected_stdout_file = if expected_stdout_file =~ %r{/}
        expected_stdout_file
      else 
        File.join("output", 'test_expected', expected_stdout_file)
      end
      @expected_output_file = if expected_output_file =~ %r{/}
        expected_output_file
      else
        File.join("output", 'test_expected', expected_output_file)
      end
      @output_file = if output_file =~ %r{/}
        output_file
      else
        File.join("output", "test_actual", output_file)
      end
    end
    it "gives the expected $stdout" do
      @res.should == Bun.readfile(@expected_stdout_file)
    end
    it "creates the expected output file (#{output_file})" do
      file_should_exist @output_file
    end
    it "puts the expected output (in #{output_file})" do
      if File.exists?(@output_file) 
        @output_file.should match_file(@expected_output_file)
      end
    end
    after :all do
      backtrace
      exec("rm #{@output_file}")
    end
  end
end
