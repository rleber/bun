#!/usr/bin/env rvm-ruby 1.9.3
# -*- encoding: us-ascii -*-

require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
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
  res = `#{cmd}`
  unless $?.exitstatus == 0
    allowed_codes = [options[:allowed] || []].flatten
    unless allowed_codes.include?(:all)
      raise RuntimeError, "Command #{cmd} failed with exit status #{$?.exitstatus}" \
          unless allowed_codes.include?($?.exitstatus)
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
        Bun.readfile(@output_file).should == Bun.readfile(@expected_output_file)
      end
    end
    after :all do
      backtrace
      exec("rm #{@output_file}")
    end
  end
end

UNPACK_PATTERNS = {
  :unpack_time=>/:unpack_time: \d{4}-\d\d-\d\d \d\d:\d\d:\d\d\.\d{9} [-+]\d\d:\d\d\n?/,
  :unpacked_by=>/:unpacked_by:\s+Bun version \d+\.\d+\.\d+\s+\[.*?\]\n?/, 
}

describe Bun::File::Text do
  include_examples "simple", "ar119.1801"
  include_examples "simple", "ar003.0698"
  
  it "decodes a more complex file (ar004.0642)" do
    infile = 'ar004.0642'
    source_file = infile + Bun::DEFAULT_UNPACKED_FILE_EXTENSION
    outfile = File.join("output", "test_expected", infile)
    decode_and_scrub(source_file, :tabs=>'80').should == rstrip(Bun.readfile(outfile))
  end
end

describe Bun::Archive do
  context "bun unpack" do
    context "with a text file" do
      context "with output to '-'" do
        before :all do
          exec("rm -f output/test_actual/unpack_ar003.0698")
          exec("rm -rf data/test/archive/general_test_packed")
          exec("cp -r data/test/archive/general_test_packed_init \
                      data/test/archive/general_test_packed")
          exec("bun unpack data/test/archive/general_test_packed/ar003.0698 - \
                    >output/test_actual/unpack_ar003.0698")
        end
        it "should match the expected output" do
          "unpack_ar003.0698".should match_expected_output_except_for(UNPACK_PATTERNS)
        end
        after :all do
          backtrace
          exec_on_success("rm -f output/test_actual/unpack_ar003.0698")
          exec_on_success("rm -rf data/test/archive/general_test_packed")
        end
      end
      context "with omitted output" do
        before :all do
          exec("rm -f output/test_actual/unpack_ar003.0698")
          exec("rm -rf data/test/archive/general_test_packed")
          exec("cp -r data/test/archive/general_test_packed_init \
                   data/test/archive/general_test_packed")
          exec("bun unpack data/test/archive/general_test_packed/ar003.0698 >output/test_actual/unpack_ar003.0698")
        end
        it "should match the expected output" do
          "unpack_ar003.0698".should match_expected_output_except_for(UNPACK_PATTERNS)
        end
        after :all do
          backtrace
          exec_on_success("rm -f output/test_actual/unpack_ar003.0698")
          exec_on_success("rm -rf data/test/archive/general_test_packed")
        end
      end
    end
    context "from STDIN" do
      context "without tape name" do
        before :all do
          exec("rm -f output/test_actual/unpack_stdin_ar003.0698")
          exec("rm -rf data/test/archive/general_test_packed")
          exec("cp -r data/test/archive/general_test_packed_init \
                  data/test/archive/general_test_packed")
          exec("cat data/test/archive/general_test_packed/ar003.0698 | \
                  bun unpack - >output/test_actual/unpack_stdin_ar003.0698")
        end
        it "should match the expected output" do
          "unpack_stdin_ar003.0698".should match_expected_output_except_for(UNPACK_PATTERNS)
        end
        after :all do
          backtrace
          exec_on_success("rm -f output/test_actual/unpack_ar003.0698")
          exec_on_success("rm -rf data/test/archive/general_test_packed")
        end
      end
      context "with tape name" do
        before :all do
          exec("rm -f output/test_actual/unpack_ar003.0698")
          exec("rm -rf data/test/archive/general_test_packed")
          exec("cp -r data/test/archive/general_test_packed_init \
                  data/test/archive/general_test_packed")
          exec("cat data/test/archive/general_test_packed/ar003.0698 | \
                  bun unpack -t ar003.0698 - >output/test_actual/unpack_ar003.0698")
        end
        it "should match the expected output" do
          "unpack_ar003.0698".should match_expected_output_except_for(UNPACK_PATTERNS)
        end
        after :all do
          backtrace
          exec_on_success("rm -f output/test_actual/unpack_ar003.0698")
          exec_on_success("rm -rf data/test/archive/general_test_packed")
        end
      end
    end
    context "with output to a file" do
      before :all do
        exec("rm -f output/test_actual/unpack_ar003.0698")
        exec("rm -rf data/test/archive/general_test_packed")
        exec("cp -r data/test/archive/general_test_packed_init data/test/archive/general_test_packed")
        exec("bun unpack data/test/archive/general_test_packed/ar003.0698 output/test_actual/unpack_ar003.0698")
      end
      it "should match the expected output" do
        "unpack_ar003.0698".should match_expected_output_except_for(UNPACK_PATTERNS)
      end
      after :all do
        backtrace
        exec_on_success("rm -f output/test_actual/unpack_ar003.0698")
        exec_on_success("rm -rf data/test/archive/general_test_packed")
      end
    end
    context "with a frozen file" do
      before :all do
        exec("rm -f output/test_actual/unpack_ar019.0175")
        exec("rm -rf data/test/archive/general_test_packed")
        exec("cp -r data/test/archive/general_test_packed_init data/test/archive/general_test_packed")
        exec("bun unpack data/test/archive/general_test_packed/ar019.0175 output/test_actual/unpack_ar019.0175")
      end
      it "should match the expected output" do
        "unpack_ar019.0175".should match_expected_output_except_for(UNPACK_PATTERNS)
      end
      after :all do
        backtrace
        exec_on_success("rm -f output/test_actual/unpack_ar019.0175")
        exec_on_success("rm -rf data/test/archive/general_test_packed")
      end
    end
  end
  
  context "bun archive unpack" do
    before :all do
      exec("rm -rf data/test/archive/general_test_packed_unpacked")
      exec("rm -f output/test_actual/archive_unpack_files.txt")
      exec("rm -f output/test_actual/archive_unpack_stdout.txt")
      exec("rm -f output/test_actual/archive_unpack_stdout.txt")
      exec("rm -rf data/test/archive/general_test_packed")
      exec("cp -r data/test/archive/general_test_packed_init data/test/archive/general_test_packed")
      exec("bun archive unpack data/test/archive/general_test_packed \
              data/test/archive/general_test_packed_unpacked 2>output/test_actual/archive_unpack_stderr.txt \
              >output/test_actual/archive_unpack_stdout.txt")
    end
    it "should create a new directory" do
      file_should_exist "data/test/archive/general_test_packed_unpacked"
    end
    it "should write nothing on stdout" do
      Bun.readfile('output/test_actual/archive_unpack_stdout.txt').chomp.should == ""
    end
    it "should write file decoding messages on stderr" do
      Bun.readfile("output/test_actual/archive_unpack_stderr.txt").chomp.should ==
      Bun.readfile('output/test_expected/archive_unpack_stderr.txt').chomp
    end
    it "should create the appropriate files" do
      exec('find data/test/archive/general_test_packed_unpacked -print \
                >output/test_actual/archive_unpack_files.txt')
      Bun.readfile('output/test_actual/archive_unpack_files.txt').chomp.should ==
      Bun.readfile('output/test_expected/archive_unpack_files.txt').chomp
    end
    after :all do
      backtrace
      exec_on_success("rm -rf data/test/archive/general_test_packed_unpacked")
      exec_on_success("rm -rf data/test/archive/general_test_packed")
      exec_on_success("rm -f output/test_actual/archive_unpack_files.txt")
      exec_on_success("rm -f output/test_actual/archive_unpack_stderr.txt")
      exec_on_success("rm -f output/test_actual/archive_unpack_stdout.txt")
    end
  end
end

describe Bun::Archive do
  before :each do
    @archive = Bun::Archive.new('data/test/archive/contents')
    $expected_archive_contents = %w{
      ar003.0698.bun
      ar054.2299.bun[brytside]
      ar054.2299.bun[disco]
      ar054.2299.bun[end]
      ar054.2299.bun[opening]
      ar054.2299.bun[santa] 
    } 
  end
  describe "contents" do
    it "retrieves correct list" do
      @archive.contents.sort.should == $expected_archive_contents
    end
    it "invokes a block" do
      foo = []
      @archive.contents {|f| foo << f.upcase }
      foo.sort.should == $expected_archive_contents.map{|c| c.upcase }
    end
    after :all do
      backtrace
    end
  end
end

# Frozen files to check ar013.0560, ar004.0888, ar019.0175

DESCRIBE_PATTERNS = {
  :unpack_time=>/Unpack Time\s+\d{4}-\d\d-\d\d \d\d:\d\d:\d\d\s+[-+]\d{4}\n?/,
  :unpacked_by=>/Unpacked By\s+Bun version \d+\.\d+\.\d+\s+\[.*?\]\n?/,
}

DECODE_PATTERNS = {
  :unpack_time=>/:unpack_time: \d{4}-\d\d-\d\d \d\d:\d\d:\d\d\.\d{9} [-+]\d\d:\d\d\n?/,
  :unpacked_by=>/:unpacked_by:\s+Bun version \d+\.\d+\.\d+\s+\[.*?\]\n?/, 
  :decode_time=>/:decode_time: \d{4}-\d\d-\d\d \d\d:\d\d:\d\d\.\d{9} [-+]\d\d:\d\d\n?/,
  :decoded_by=>/:decoded_by:\s+Bun version \d+\.\d+\.\d+\s+\[.*?\]\n?/, 
}

describe Bun::Bot do
  # include_examples "command", "descr", "cmd", "expected_stdout_file"
  # include_examples "command with file", "descr", "cmd", "expected_stdout_file", "output_in_file", "expected_output_file"
  describe "scrub" do
    include_examples "command", "scrub", "scrub data/test/clean", "scrub"
    include_examples "command from STDIN", 
                     "scrub", 
                     "scrub -",
                     "data/test/clean", 
                     "scrub"
    after :all do
      backtrace
    end
  end

  describe "examine" do
    include_examples "command", "examine clean file", "examine -t --asis -e clean data/test/clean", "examine_clean"
    include_examples "command from STDIN", "examine clean file", 
        "examine -t --asis -e clean -", "data/test/clean", "examine_clean"
    
    # Dirty file is just the packed version of ar119.1801
    include_examples "command", "examine dirty file", "examine -t --asis -e clean data/test/dirty", "examine_dirty",
                     :allowed=>[1]
    include_examples "command", "examine promotes file", 
      "examine -t -e clean data/test/packed_ar003.0698", "examine_clean",
                       :allowed=>[1] # Because we're testing the output; it's more helpful
                                     # to allow a non-zero return code
    include_examples "command", "examine does not promote file with --asis", 
      "examine -t --asis -e clean data/test/packed_ar003.0698", "examine_dirty",
                       :allowed=>[1]
    after :all do
      backtrace
    end
  end
    
  describe "describe" do
    describe "with text file" do
      before :all do
        exec("bun describe #{TEST_ARCHIVE}/ar003.0698.bun >output/test_actual/describe_ar003.0698")
      end
      it "should match the expected output" do
        "describe_ar003.0698".should match_expected_output_except_for(DESCRIBE_PATTERNS)
      end
      after :all do
        backtrace
      end
    end
    describe "with frozen file" do
      before :all do
        exec("bun describe #{TEST_ARCHIVE}/ar025.0634.bun >output/test_actual/describe_ar025.0634")
      end
      it "should match the expected output (including quoting)" do
        "describe_ar025.0634".should match_expected_output_except_for(DESCRIBE_PATTERNS)
      end
      after :all do
        backtrace
      end
    end
  
    context "functioning outside the base directory" do
      before :each do
        raise RuntimeError, "In unexpected working directory: #{Dir.pwd}" \
          unless File.expand_path(Dir.pwd) == File.expand_path(File.join(File.dirname(__FILE__),'..'))
        @original_dir = Dir.pwd
      end
      it "should start in the base directory" do
        File.expand_path(Dir.pwd).should == File.expand_path(File.join(File.dirname(__FILE__),'..'))
      end
      it "should function okay in a different directory" do
        exec("cd ~ ; bun describe #{TEST_ARCHIVE}/ar003.0698.bun")
        $?.exitstatus.should == 0
      end
      after :each do
        Dir.chdir(@original_dir)
        raise RuntimeError, "Not back in normal working directory: #{Dir.pwd}" \
          unless File.expand_path(Dir.pwd) == File.expand_path(File.join(File.dirname(__FILE__),'..'))
      end
      after :all do
        backtrace
      end
    end
  end  
  
  describe "mark" do
    context "with no output file" do
      before :all do
        exec "rm -f data/test/mark_source.bun"
        exec "cp data/test/mark_source_init.bun data/test/mark_source.bun"
        exec "bun describe data/test/mark_source.bun >output/test_actual/mark_source_before"
        exec "bun mark -t \" foo : bar , named:'abc,d\\\\'ef '\" data/test/mark_source.bun"
        exec "bun describe data/test/mark_source.bun >output/test_actual/mark_source_after"
      end
      it "should have the expected input" do
        "mark_source_before".should match_expected_output_except_for(DESCRIBE_PATTERNS)
      end
      it "should create the expected marks in the existing file" do
        "mark_source_after".should match_expected_output_except_for(DESCRIBE_PATTERNS)
      end
      after :all do
        backtrace
        exec_on_success "rm -f data/test/mark_source.bun"
        exec_on_success "rm -f output/test_actual/mark_source_before"
        exec_on_success "rm -f output/test_actual/mark_source_after"
      end
    end
    context "with an output file" do
      before :all do
        exec "rm -f data/test/mark_source.bun"
        exec "cp data/test/mark_source_init.bun data/test/mark_source.bun"
        exec "bun describe data/test/mark_source.bun >output/test_actual/mark_source_before"
        exec "rm -f data/test/mark_result.bun"
        exec "bun mark -t \" foo : bar , named:'abc,d\\\\'ef '\" \
                  data/test/mark_source.bun data/test/mark_result.bun"
        exec "bun describe data/test/mark_source.bun >output/test_actual/mark_source_after"
        exec "bun describe data/test/mark_result.bun >output/test_actual/mark_result_after"
      end
      it "should have the expected input" do
        "mark_source_before".should match_expected_output_except_for(DESCRIBE_PATTERNS)
      end
      it "should create the new file" do
        file_should_exist "data/test/mark_result.bun"
      end
      it "should create the expected marks in the new file" do
        "mark_result_after".should match_expected_output_except_for(DESCRIBE_PATTERNS)
      end
      it "should have leave the existing file unchanged" do
        Bun.readfile("output/test_actual/mark_source_after").chomp.should ==
        Bun.readfile('output/test_actual/mark_source_before').chomp
      end
      after :all do
        backtrace
        exec_on_success "rm -f data/test/mark_source.bun"
        exec_on_success "rm -f data/test/mark_result.bun"
        exec_on_success "rm -f output/test_actual/mark_source_before"
        exec_on_success "rm -f output/test_actual/mark_source_after"
        exec_on_success "rm -f output/test_actual/mark_result_after"
      end
    end
    context "with '-' as output file" do
      before :all do
        exec "rm -f data/test/mark_source.bun"
        exec "cp data/test/mark_source_init.bun data/test/mark_source.bun"
        exec "bun describe data/test/mark_source.bun >output/test_actual/mark_source_before"
        exec "rm -f output/test_actual/mark_result.bun"
        exec "bun mark -t \" foo : bar , named:'abc,d\\\\'ef '\" \
                  data/test/mark_source.bun - >output/test_actual/mark_result.bun"
        exec "bun describe data/test/mark_source.bun >output/test_actual/mark_source_after"
        exec "bun describe output/test_actual/mark_result.bun >output/test_actual/mark_result_after"
      end
      it "should have the expected input" do
        "mark_source_before".should match_expected_output_except_for(DESCRIBE_PATTERNS)
      end
      it "should create the expected marks on STDOUT" do
        "mark_result_after".should match_expected_output_except_for(DESCRIBE_PATTERNS)
      end
      it "should have leave the existing file unchanged" do
        Bun.readfile("output/test_actual/mark_source_after").chomp.should ==
        Bun.readfile('output/test_actual/mark_source_before').chomp
      end
      after :all do
        backtrace
        exec_on_success "rm -f data/test/mark_source.bun"
        exec_on_success "rm -f output/test_actual/mark_result.bun"
        exec_on_success "rm -f output/test_actual/mark_source_before"
        exec_on_success "rm -f output/test_actual/mark_source_after"
        exec_on_success "rm -f output/test_actual/mark_result_after"
      end
    end
    context "with '-' as input file" do
      before :all do
        exec "rm -f data/test/mark_source.bun"
        exec "cp data/test/mark_source_init.bun data/test/mark_source.bun"
        exec "bun describe data/test/mark_source.bun >output/test_actual/mark_source_before"
        exec "rm -f data/test/mark_result.bun"
        exec "cat data/test/mark_source.bun | \
              bun mark -t \" foo : bar , named:'abc,d\\\\'ef '\" \
                  - data/test/mark_result.bun"
        exec "bun describe data/test/mark_source.bun >output/test_actual/mark_source_after"
        exec "bun describe data/test/mark_result.bun >output/test_actual/mark_result_after"
      end
      it "should have the expected input" do
        "mark_source_before".should match_expected_output_except_for(DESCRIBE_PATTERNS)
      end
      it "should create the new file" do
        file_should_exist "data/test/mark_result.bun"
      end
      it "should create the expected marks in the new file" do
        "mark_result_after".should match_expected_output_except_for(DESCRIBE_PATTERNS)
      end
      it "should have leave the existing file unchanged" do
        Bun.readfile("output/test_actual/mark_source_after").chomp.should ==
        Bun.readfile('output/test_actual/mark_source_before').chomp
      end
      after :all do
        backtrace
        exec_on_success "rm -f data/test/mark_source.bun"
        exec_on_success "rm -f data/test/mark_result.bun"
        exec_on_success "rm -f output/test_actual/mark_source_before"
        exec_on_success "rm -f output/test_actual/mark_source_after"
        exec_on_success "rm -f output/test_actual/mark_result_after"
      end
    end
  end
  
  describe "ls" do
    include_examples "command", "ls", "ls #{TEST_ARCHIVE}", "ls"
    include_examples "command", "ls -o", "ls -o #{TEST_ARCHIVE}", "ls_o"
    include_examples "command", 
                     "ls -ldr with text file (ar003.0698)", 
                     "ls -ldr #{TEST_ARCHIVE}/ar003.0698.bun", 
                     "ls_ldr_ar003.0698"
    include_examples "command", 
                     "ls -ldr with frozen file (ar145.2699)", 
                     "ls -ldr #{TEST_ARCHIVE}/ar145.2699.bun", 
                     "ls_ldr_ar145.2699"
    include_examples "command", "ls with glob", "ls #{TEST_ARCHIVE}/ar08*", "ls_glob"
    after :all do
      backtrace
    end
  end

  describe "readme" do
    include_examples "command", "readme", "readme", "doc/readme.md"
    after :all do
      backtrace
    end
  end

  describe "decode" do
    context "with text file" do
      before :all do
        exec("rm -f output/test_actual/decode_ar003.0698")
        exec("bun decode #{TEST_ARCHIVE}/ar003.0698.bun \
                  >output/test_actual/decode_ar003.0698")
      end
      it "should match the expected output" do
        "decode_ar003.0698".should match_expected_output_except_for(DECODE_PATTERNS)
      end
      after :all do
        backtrace
        exec_on_success("rm -f output/test_actual/decode_ar003.0698")
      end
    end
    context "from STDIN" do
      before :all do
        exec("rm -f output/test_actual/decode_ar003.0698")
        exec("cat #{TEST_ARCHIVE}/ar003.0698.bun | bun decode - \
                  >output/test_actual/decode_ar003.0698")
      end
      it "should match the expected output" do
        "decode_ar003.0698".should match_expected_output_except_for(DECODE_PATTERNS)
      end
      after :all do
        backtrace
        exec_on_success("rm -f output/test_actual/decode_ar003.0698")
      end
    end
    context "with frozen file" do
      context "and +0 shard argument" do
        before :all do
          exec("rm -f output/test_actual/decode_ar004.0888")
          exec("bun decode -s +0 #{TEST_ARCHIVE}/ar004.0888.bun \
                    >output/test_actual/decode_ar004.0888_0")
        end
        it "should match the expected output" do
          "decode_ar004.0888_0".should match_expected_output_except_for(DECODE_PATTERNS)
        end
        after :all do
          backtrace
          exec_on_success("rm -f output/test_actual/decode_ar004.0888_0")
        end
      end
      context "and [+0] shard syntax" do
        before :all do
          exec("rm -f output/test_actual/decode_ar004.0888")
          exec("bun decode #{TEST_ARCHIVE}/ar004.0888.bun[+0] \
                    >output/test_actual/decode_ar004.0888_0")
        end
        it "should match the expected output" do
          "decode_ar004.0888_0".should match_expected_output_except_for(DECODE_PATTERNS)
        end
        after :all do
          backtrace
          exec_on_success("rm -f output/test_actual/decode_ar004.0888_0")
        end
      end
      context "and [name] shard syntax" do
        before :all do
          exec("rm -f output/test_actual/decode_ar004.0888_0")
          exec("bun decode #{TEST_ARCHIVE}/ar004.0888.bun[fasshole] \
                    >output/test_actual/decode_ar004.0888_0")
        end
        it "should match the expected output" do
          "decode_ar004.0888_0".should match_expected_output_except_for(DECODE_PATTERNS)
        end
        after :all do
          backtrace
          exec_on_success("rm -f output/test_actual/decode_ar004.0888_0")
        end
      end
    end
  end

  describe "dump" do
    include_examples "command", 
                     "dump ar003.0698", 
                     "dump #{TEST_ARCHIVE}/ar003.0698.bun", 
                     "dump_ar003.0698"
    include_examples "command", 
                     "dump -s ar003.0698", 
                     "dump -s #{TEST_ARCHIVE}/ar003.0698.bun",
                     "dump_s_ar003.0698"
    include_examples "command", 
                     "dump ar004.0888", 
                     "dump #{TEST_ARCHIVE}/ar004.0888.bun", 
                     "dump_ar004.0888"
    include_examples "command", 
                     "dump -f ar004.0888", 
                     "dump -f #{TEST_ARCHIVE}/ar004.0888.bun",
                     "dump_f_ar004.0888"
    include_examples "command from STDIN", 
                     "dump ar003.0698", 
                     "dump - ", 
                     "#{TEST_ARCHIVE}/ar003.0698.bun", 
                     "dump_stdin_ar003.0698"
    after :all do
      backtrace
    end
  end

  describe "freezer" do
    context "ls" do
      include_examples "command", 
                       "freezer ls ar004.0888", 
                       "freezer ls #{TEST_ARCHIVE}/ar004.0888.bun",
                       "freezer_ls_ar004.0888"
      include_examples "command", 
                       "freezer ls -l ar004.0888", 
                       "freezer ls -l #{TEST_ARCHIVE}/ar004.0888.bun", 
                       "freezer_ls_l_ar004.0888"
      include_examples "command from STDIN", 
                       "freezer ls ar004.0888", 
                       "freezer ls -",
                       "#{TEST_ARCHIVE}/ar004.0888.bun",
                       "freezer_ls_stdin_ar004.0888"
      after :all do
        backtrace
      end
    end
    context "dump" do
      include_examples "command", 
                       "freezer dump ar004.0888 +0", 
                       "freezer dump #{TEST_ARCHIVE}/ar004.0888.bun +0", 
                       "freezer_dump_ar004.0888_0"
      include_examples "command", 
                       "freezer dump -s ar004.0888 +0", 
                       "freezer dump -s #{TEST_ARCHIVE}/ar004.0888.bun +0", 
                       "freezer_dump_s_ar004.0888_0"
      include_examples "command from STDIN", 
                       "freezer dump ar004.0888 +0", 
                       "freezer dump - +0",
                       "#{TEST_ARCHIVE}/ar004.0888.bun", 
                       "freezer_dump_stdin_ar004.0888_0"
      after :all do
        backtrace
      end
    end
  end

  describe "catalog" do
    before :all do
      exec("rm -rf data/test/archive/catalog_source")
      exec("cp -r data/test/archive/catalog_source_init data/test/archive/catalog_source")
      exec("bun archive catalog data/test/archive/catalog_source --catalog data/test/catalog.txt \
                2>output/test_actual/archive_catalog_stderr.txt >output/test_actual/archive_catalog_stdout.txt")
    end
    it "should write nothing on stdout" do
      Bun.readfile('output/test_actual/archive_catalog_stdout.txt').chomp.should == ""
    end
    it "should write file decoding messages on stderr" do
      Bun.readfile("output/test_actual/archive_catalog_stderr.txt").chomp.should ==
      Bun.readfile('output/test_expected/archive_catalog_stderr.txt').chomp
    end
    it "should not add or remove any files in the archive" do
      exec('find data/test/archive/catalog_source -print >output/test_actual/archive_catalog_files.txt')
      Bun.readfile('output/test_actual/archive_catalog_files.txt').chomp.should ==
      Bun.readfile('output/test_expected/archive_catalog_files.txt').chomp
    end
    it "should change the catalog dates in the catalog" do 
    end
    after :all do
      backtrace
      exec_on_success("rm -rf data/test/archive/catalog_source")
      exec_on_success("rm -f output/test_actual/archive_catalog_stderr.txt")
      exec_on_success("rm -f output/test_actual/archive_catalog_stdout.txt")
      exec_on_success("rm -f output/test_actual/archive_catalog_files.txt")
    end
  end

  describe "archive decode" do
    before :all do
      exec("rm -rf data/test/archive/decode_source")
      exec("rm -rf data/test/archive/decode_archive")
      exec("cp -r data/test/archive/decode_source_init data/test/archive/decode_source")
      exec("bun archive decode data/test/archive/decode_source data/test/archive/decode_archive \
                2>output/test_actual/archive_decode_stderr.txt >output/test_actual/archive_decode_stdout.txt")
    end
    it "should create a tapes directory" do
      file_should_exist "data/test/archive/decode_archive"
    end
    it "should write nothing on stdout" do
      Bun.readfile('output/test_actual/archive_decode_stdout.txt').chomp.should == ""
    end
    it "should write file decoding messages on stderr" do
      Bun.readfile("output/test_actual/archive_decode_stderr.txt").chomp.should ==
      Bun.readfile('output/test_expected/archive_decode_stderr.txt').chomp
    end
    it "should create the appropriate files" do
      exec('find data/test/archive/decode_archive -print >output/test_actual/archive_decode_files.txt')
      Bun.readfile('output/test_actual/archive_decode_files.txt').chomp.should ==
      Bun.readfile('output/test_expected/archive_decode_files.txt').chomp
    end
    after :all do
      backtrace
      exec_on_success("rm -rf data/test/archive/decode_source")
      exec_on_success("rm -rf data/test/archive/decode_archive")
      exec_on_success("rm -f output/test_actual/archive_decode_stderr.txt")
      exec_on_success("rm -f output/test_actual/archive_decode_stdout.txt")
      exec_on_success("rm -f output/test_actual/archive_decode_files.txt")
    end
  end

  describe "archive compact" do
    before :all do
      exec("rm -rf data/test/archive/compact_files")
      exec("rm -rf data/test/archive/compact_result")
      exec("cp -r data/test/archive/compact_source_init data/test/archive/compact_source")
      exec("bun archive compact data/test/archive/compact_source data/test/archive/compact_result")
    end
    it "should create the results directory" do
      file_should_exist "data/test/archive/compact_result"
    end
    after :all do
      backtrace
      exec_on_success("rm -rf data/test/archive/compact_source")
      exec_on_success("rm -rf data/test/archive/compact_result")
    end
  end
end