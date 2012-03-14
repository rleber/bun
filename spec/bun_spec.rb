require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'tempfile'

def unpack(text)
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

shared_examples "command" do |descr, command, output|
  it "handles #{descr} properly" do
    # warn "> bun #{command}"
    res = `bun #{command} 2>&1`
    output = File.join("output", 'test', output) unless output =~ %r{/}
    unpack(res).should == readfile(output)
  end
end

describe Bun::File::Text do
  include_examples "simple", "ar119.1801"
  include_examples "simple", "ar003.0698"
  
  # TODO Create a listing file class
  it "decodes a more complex file (ar004.0642)" do
    infile = 'ar004.0642'
    outfile = File.join("output", "test", infile)
    decode_and_scrub(infile, :tabs=>'80').should == readfile(outfile)
  end
end

# Frozen files to check ar013.0560, ar004.0888, ar019.0175

describe Bun::Bot do
  # include_examples "command", "descr", "cmd", "output"
  describe "check" do
    include_examples "command", "check clean file", "check data/test/clean", "check_clean"
    include_examples "command", "check dirty file", "check data/test/ar119.1801", "check_dirty"
  end
    
  describe "describe" do
    include_examples "command", "describe text file", "describe ar025.0634", "describe_ar025.0634"
    include_examples "command", "describe frozen file", "describe ar025.0634", "describe_ar025.0634"
  end
  describe "ls" do
    include_examples "command", "ls", "ls", "ls"
    include_examples "command", "ls -ldr with text file", "ls -ldr -t ar003.0698", "ls_ldrt_ar003.0698"
    include_examples "command", "ls -ldr with frozen file", "ls -ldr -t ar004.0888", "ls_ldrt_ar004.0888"
    include_examples "command", "ls -ldr with frozen file (check dates)", "ls -ldr -t ar145.2699", "ls_ldrt_ar145.2699"
  end
  describe "readme" do
    include_examples "command", "readme", "readme", "doc/readme.md"
  end
  describe "unpack" do
    include_examples "command", "unpack", "unpack ar003.0698", "unpack"
  end
end
