#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'tempfile'
require 'yaml'

def unpack(text)
  if RUBY_VERSION !~ /^1\.8/
    text = text.force_encoding("ascii-8bit")
  end
  lines = text.split("\n").map{|line| line.rstrip}
  lines.pop if lines.last == ""
  lines
end

def decode(file_name)
  archive = Bun::Archive.new
  expanded_file = File.join("data", "test", file_name)
  file = Bun::File::Text.open(expanded_file)
  unpack(file.text)
end

def readfile(file)
  unpack(File.read(file))
end

def scrub(lines, options={})
  tabs = options[:tabs] || '80'
  tempfile = Tempfile.new('bun1')
  tempfile2 = Tempfile.new('bun2')
  tempfile.write(lines.join("\n"))
  tempfile.close
  tempfile2.close
  system("cat #{tempfile.path.inspect} | ruby -p -e '$_.gsub!(/_\\x8/,\"\")' | expand -t #{tabs} >#{tempfile2.path.inspect}")
  unpack(File.read(tempfile2.path))
end

def decode_and_scrub(file, options={})
  scrub(decode(file), options)
end

shared_examples "simple" do |file|
  it "decodes a simple text file (#{file})" do
    infile = file
    outfile = File.join("output", "test", infile)
    decode(infile).should == readfile(outfile)
  end
end

shared_examples "command" do |descr, command, expected_stdout_file|
  it "handles #{descr} properly" do
    # warn "> bun #{command}"
    res = `bun #{command} 2>&1`
    expected_stdout_file = File.join("output", 'test', expected_stdout_file) unless expected_stdout_file =~ %r{/}
    unpack(res).should == readfile(expected_stdout_file)
  end
end

shared_examples "command with file" do |descr, command, expected_stdout_file, output_file, expected_output_file|
  context descr do
    before :all do
      # warn "> bun #{command}"
      @res = `bun #{command} 2>&1`
      @expected_stdout_file = if expected_stdout_file =~ %r{/}
        expected_stdout_file
      else 
        File.join("output", 'test', expected_stdout_file)
      end
      @expected_output_file = if expected_output_file =~ %r{/}
        expected_output_file
      else
        File.join("output", 'test', expected_output_file)
      end
      @output_file = if output_file =~ %r{/}
        output_file
      else
        File.join("output", output_file)
      end
    end
    it "gives the expected $stdout" do
      unpack(@res).should == readfile(@expected_stdout_file)
    end
    it "creates the expected output file (#{output_file})" do
      file_should_exist @output_file
    end
    it "puts the expected output (in #{output_file})" do
      if File.exists?(@output_file) 
        readfile(@output_file).should == readfile(@expected_output_file)
      end
    end
    after :all do
      `rm #{@output_file}`
    end
  end
end

describe Bun::File::Text do
  include_examples "simple", "ar119.1801"
  include_examples "simple", "ar003.0698"
  
  it "decodes a more complex file (ar004.0642)" do
    infile = 'ar004.0642'
    outfile = File.join("output", "test", infile)
    decode_and_scrub(infile, :tabs=>'80').should == readfile(outfile)
  end
end

describe Bun::Archive do
  before :each do
    @archive = Bun::Archive.new('data/test/archive/contents')
  end
  describe "contents" do
    it "retrieves correct list" do
      @archive.contents.sort.should == %w{ar003.0698 ar054.2299::brytside ar054.2299::disco 
                                          ar054.2299::end ar054.2299::opening ar054.2299::santa }
    end
    it "invokes a block" do
      foo = []
      @archive.contents {|f| foo << f }
      foo.sort.should == %w{ar003.0698 ar054.2299::brytside ar054.2299::disco 
                            ar054.2299::end ar054.2299::opening ar054.2299::santa }
    end
  end
end

# Frozen files to check ar013.0560, ar004.0888, ar019.0175

describe Bun::Bot do
  # include_examples "command", "descr", "cmd", "expected_stdout_file"
  # include_examples "command with file", "descr", "cmd", "expected_stdout_file", "output_in_file", "expected_output_file"
  describe "check" do
    include_examples "command", "check clean file", "check data/test/clean", "check_clean"
    include_examples "command", "check dirty file", "check data/test/ar119.1801", "check_dirty"
  end
    
  describe "describe" do
    include_examples "command", "describe text file", "describe ar003.0698", "describe_ar003.0698"
    include_examples "command", "describe frozen file", "describe ar025.0634", "describe_ar025.0634"
  end
  describe "ls" do
    include_examples "command", "ls", "ls", "ls"
    include_examples "command", "ls -ldr with text file (ar003.0698)", "ls -ldr -t ar003.0698", "ls_ldrt_ar003.0698"
    include_examples "command", "ls -ldr with frozen file (ar145.2699)", "ls -ldr -t ar145.2699", "ls_ldrt_ar145.2699"
    include_examples "command", "ls -ldrb with frozen file (ar145.2699)", "ls -ldrb -t ar145.2699", "ls_ldrbt_ar145.2699"
  end
  describe "readme" do
    include_examples "command", "readme", "readme", "doc/readme.md"
  end
  describe "unpack" do
    include_examples "command", "unpack", "unpack ar003.0698", "unpack"
  end
  describe "cat" do
    include_examples "command", "cat (ar003.0698)", "cat ar003.0698", "cat"
  end
  describe "cp" do
    include_examples "command with file", 
      "cp ar003.0698 output/cp_ar003.0698.out", "cp ar003.0698 output/cp_ar003.0698.out", 
      "cp_ar003.0698.stdout", "cp_ar003.0698.out", "cp_ar003.0698"
    include_examples "command", "cp ar003.0698 -", "cp ar003.0698 -", "cp_ar003.0698"
    include_examples "command", "cp ar003.0698", "cp ar003.0698 -", "cp_ar003.0698"
    include_examples "command with file", 
      "cp ar003.0698 output/cp_ar003.0698 (a directory)", "cp ar003.0698 output/cp_ar003.0698", 
      "cp_ar003.0698.stdout", "output/cp_ar003.0698/ar003.0698", "cp_ar003.0698"
  end
  context "index processing" do
    before :each do
      `rm -rf data/test/archive/index`
      `cp -r data/test/archive/init data/test/archive/index`
    end
    context "index build" do
      before :each do
        `rm -f data/test/archive/index/.index.yml`
        `bun archive index build --archive "data/test/archive/index"`
      end
      it "should create index" do
        file_should_exist "data/test/archive/index/.index.yml"
      end
      it "should be a good YAML file" do
        expect { YAML.load(::File.read("data/test/archive/index/.index.yml")) }.should_not raise_error
      end
      if (YAML.load(::File.read("data/test/archive/index/.index.yml")) rescue nil)
        context "index contents" do
          before :each do
            @index = YAML.load(::File.read("data/test/archive/index/.index.yml")) rescue nil
          end
          it "should be a Hash" do
            @index.should be_a(Hash)
          end
          it "should have one entry, for ar003.0698" do
            @index.keys.should == ['ar003.0698']
          end
        end
      end
    end
    context "index clear" do
      before :each do
        `rm -f data/test/archive/index/.index.yml`
        `bun archive index build --archive "data/test/archive/index"`
        `bun archive index clear --archive "data/test/archive/index"`
      end
      it "should remove index" do
        file_should_not_exist "data/test/archive/index/.index.yml"
      end
    end
    after :each do
      `rm -rf data/test/archive/index`
    end
  end
  context "bun ls handling of the index" do
    context "from the index" do
      before :each do
        lines = `bun ls --archive "data/test/archive/strange" | tail -n 1`.chomp
        @file = lines.split(/\s+/)[-1].strip
      end
      it "should pull data from the index" do
        @file.should == "from_the_index"
      end
    end
    context "built from the file" do
      before :each do
        lines = `bun ls --archive "data/test/archive/strange" --build | tail -n 1`.chomp
        @file = lines.split(/\s+/)[-1].strip
      end
      it "should not pull data from the index" do
        @file.should_not == "from_the_index"
      end
    end
  end
  context "bun describe handling of the index" do
    context "from the index" do
      before :each do
        lines = `bun describe --archive "data/test/archive/strange" ar003.0698`.chomp.split("\n")
        @file = lines.find {|line| line =~ /^Name:/}.split(/\s+/)[-1].strip
      end
      it "should pull data from the index" do
        @file.should == "from_the_index"
      end
    end
    context "built from the file" do
      before :each do
        lines = `bun describe --archive "data/test/archive/strange" --build ar003.0698`.chomp.split("\n")
        @file = lines.find {|line| line =~ /^Name:/}.split(/\s+/)[-1].strip
      end
      it "should not pull data from the index" do
        @file.should_not == "from_the_index"
      end
    end
  end
  context "bun dump" do
    include_examples "command", "dump ar003.0698", "dump ar003.0698", "dump_ar003.0698"
    include_examples "command", "dump -f ar004.0888", "dump -f ar004.0888", "dump_f_ar004.0888"
  end
  context "bun freezer" do
    context "ls" do
      include_examples "command", "freezer ls ar004.0888", "freezer ls ar004.0888", "freezer_ls_ar004.0888"
      include_examples "command", "freezer ls -l ar004.0888", "freezer ls -l ar004.0888", "freezer_ls_l_ar004.0888"
      include_examples "command", "freezer ls -d ar004.0888", "freezer ls -d ar004.0888", "freezer_ls_d_ar004.0888"
    end
    context "dump" do
      include_examples "command", "freezer dump ar004.0888 +0", "freezer dump ar004.0888 +0", "freezer_dump_ar004.0888_0"
    end
    context "thaw" do
      include_examples "command", "freezer thaw ar004.0888 +0", "freezer thaw ar004.0888 +0", "freezer_thaw_ar004.0888_0"
    end
  end
end