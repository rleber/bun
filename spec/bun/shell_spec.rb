#!/usr/bin/env rvm-ruby 1.9.3
# -*- encoding: us-ascii -*-

describe Bun::Shell do
  context "write" do
    context "with null file" do
      before :all do
        @shell = Bun::Shell.new
        @stdout_content = capture(:stdout) { @res = @shell.write(nil, "foo") }
      end
      it "should return the text" do
        @res.should == "foo"
      end
      it "should write nothing to $stdout" do
        @stdout_content.should == ""
      end
    end
    context "with - as file" do
      before :all do
        @shell = Bun::Shell.new
        @stdout_content = capture(:stdout) { @res = @shell.write("-", "foo") }
      end
      it "should return the text" do
        @res.should == "foo"
      end
      it "should write the text to $stdout" do
        @stdout_content.should == "foo"
      end
    end
    context "with other file name" do
      before :all do
        @shell = Bun::Shell.new
        @file = "output/test_actual/shell_write_test.txt"
        exec("rm -f #{@file}")
        @res = @shell.write(@file, "foo")
      end
      it "should return the text" do
        @res.should == "foo"
      end
      it "should write the text to the file given" do
        file_should_exist @file
        content = ::File.read(@file)
        content.should == "foo"
      end
      after :all do
        exec("rm -f #{@file}")
      end
    end
  end
end
