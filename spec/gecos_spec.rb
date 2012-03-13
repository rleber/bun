require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'tempfile'

def decode(file_name)
  archive = GECOS::Archive.new
  expanded_file = File.join("data", "test", file_name)
  file = GECOS::File::Text.open(expanded_file)
  file.text.split("\n")
end

def readfile(file)
  File.read(file).split("\n")
end

def scrub(lines, options={})
  tabs = options[:tabs] || '80'
  tempfile = Tempfile.new('gecos1')
  tempfile2 = Tempfile.new('gecos2')
  tempfile.write(lines.join("\n"))
  tempfile.close
  tempfile2.close
  system("cat #{tempfile.path.inspect} | ruby -p -e '$_.gsub!(/_\\x8/,\"\")' | expand -t #{tabs} >#{tempfile2.path.inspect}")
  File.read(tempfile2.path).split("\n")
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

shared_examples "command" do |command|
  command_name = command.split(/\s+/).first
  it "handles #{('gecos ' + command).inspect} command properly" do
    res = `gecos #{command} 2>&1`
    res.chomp.split("\n").should == readfile(File.join("output", 'test', command_name))
  end
end

describe GECOS::File::Text do
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

describe GECOS::Bot do
  include_examples "command", "ls -ldr"
  include_examples "command", "describe ar004.0888"
end
