#!/usr/bin/env rvm-ruby 1.9.3
# -*- encoding: us-ascii -*-

describe Bun::File::Normal do
  include_examples "simple", "ar119.1801"
  include_examples "simple", "ar003.0698"
  
  it "decodes a more complex file (ar004.0642)" do
    infile = 'ar004.0642'
    source_file = infile + Bun::DEFAULT_UNPACKED_FILE_EXTENSION
    outfile = File.join("output", "test_expected", infile)
    res = decode_and_scrub(source_file, :tabs=>'80')
    res.should == rstrip(Bun.readfile(outfile))
  end
end
