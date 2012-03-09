require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'tempfile'

def decode(file)
  archive = GECOS::Archive.new
  expanded_file = File.join("data", "test", file)
  decoder = GECOS::Decoder.new(:data=>File.read(expanded_file))
  decoder.content.split("\n")
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

describe GECOS::Decoder do
  it "decodes a simple file (ar119.1801)" do
    infile = 'ar119.1801'
    outfile = File.join("output", "test", infile)
    decode(infile).should == readfile(outfile)
  end
  
  it "decodes a more complex file (ar004.0642)" do
    infile = 'ar004.0642'
    outfile = File.join("output", "test", infile)
    decode_and_scrub(infile, :tabs=>'80').should == readfile(outfile)
  end
end
