#!/usr/bin/env rvm-ruby 1.9.3
# -*- encoding: us-ascii -*-

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
