require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

def decode(file)
  archive = GECOS::Archive.new
  expanded_file = File.join("data", "test", file)
  decoder = GECOS::Decoder.new(:data=>File.read(expanded_file))
  decoder.content.split("\n")
end

def readfile(file)
  File.read(file).split("\n")
end

describe GECOS::Decoder do
  it "decodes a sample file" do
    infile = 'ar119.1801'
    outfile = File.join("output", "test", infile)
    decode(infile).should == readfile(outfile)
  end
end
