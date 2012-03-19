#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

require File.join(File.dirname(__FILE__), '../lib/lazy_array')

SIZE = 10

describe LazyArray do
  before :each do
    @ary = LazyArray.new(SIZE) do |i|
      $retrieval_counts ||= []
      $retrieval_counts[i] ||= 0
      $retrieval_counts[i] += 1
      i
    end
    $retrieval_counts = []
  end

  describe "[]" do
    (0...SIZE).each do |i|
      it "works for index #{i}" do
        @ary[i].should == i
      end
    end
    
    it "detects end of the array" do
      @ary[SIZE].should be_nil
    end
  end
  
  describe "<<" do
    it "works" do
      @ary << 99
      @ary[-1].should == 99
    end
    
    it "resets size" do
      @ary << 99
      @ary.size.should == SIZE+1
    end
  end
  
  describe "size" do
    it "should work" do
      @ary.size.should == SIZE
    end
  end
  
  describe "size=" do
    it "should work" do
      @ary.size= SIZE.div(2)
      @ary.size.should == SIZE.div(2)
    end
    
    it "should reset size" do
      @ary.size -= 1
      @ary[SIZE-1].should be_nil
    end
  end
  
  describe "[]=" do
    it "should work" do
      @ary[1] = 'foo'
      @ary[1].should == 'foo'
    end
    
    it "should not shorten size" do
      expect { @ary[1] = 'foo' }.not_to change { @ary.size }
    end
    
    it "should extend size" do
      @ary[SIZE+2] = 'bat'
      @ary.size.should == (SIZE+3)
    end
  end
  
  describe "+" do
    it "should add values" do
      (@ary + [99,98]).size.should == (SIZE+2)
      (@ary + [99,98])[-2].should == 99
      (@ary + [99,98])[-1].should == 98
    end

    it "should retain original values" do
      (@ary + [99,98])[0].should == 0
      (@ary + [99,98])[SIZE-1].should == SIZE-1
    end
    
    it "should return a LazyArray" do
      (@ary + [99,98]).should be_a LazyArray
    end
  end
  
  describe "+=" do
    it "should add values" do
      @ary += [99,98]
      @ary.size.should == (SIZE+2)
      @ary[-2].should == 99
      @ary[-1].should == 98
    end
  end
  
  describe "first" do
    it "should work" do
      @ary.first.should == 0
    end
  end
  
  describe "last" do
    it "should work" do
      @ary.last.should == SIZE-1
    end
  end
  
  describe "retrieval" do
    it "should only happen once" do
      5.times { @ary[2] }
      $retrieval_counts[2].should == 1
    end
  end
  
  describe "to_a" do
    it "should work" do
      @ary.to_a.should == (0...SIZE).to_a
    end
  end
  
  describe "==" do
    it "should compare to other arrays" do
      @ary.should == (0...SIZE).to_a
    end
  end
end