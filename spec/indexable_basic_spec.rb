require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

class Echo
  include Indexable::Basic
  
  def initialize(size)
    @size = size
  end
  
  def at(ix)
    return ix
  end
  
  def size
    return @size
  end
end
    

describe Indexable::Basic do
  before do
    @echo = Echo.new(5)
  end
  
  
  context "with single indexes" do
    (0...5).each do |i|
      it "understands non-negative indexes (e.g. #{i})" do
        @echo[i].should == i
      end
    end

    (-5..-1).each do |i|
      it "understands negative indexes (e.g. #{i})" do
        @echo[i].should == (5+i)
      end
    end

    (5..10).each do |i|
      it "returns nil for indexes above the range (e.g. #{i})" do
        @echo[i].should be_nil
      end
    end

    (-10..-6).each do |i|
      it "returns nil for indexes below the range (e.g. #{i})" do
        @echo[i].should be_nil
      end
    end
  end
  
  context "with index ranges" do
    
    it "understands negative start indexes" do
      @echo[-3..3].should == [2,3]
    end
    
    it "understands negative end indexes" do
      @echo[2..-2].should == [2,3]
    end

    context "with inclusive ranges" do
      it "returns all elements" do
        @echo[0..4].should == (0...5).to_a
      end
  
      context "with end > start" do
        it "understands the boundary case" do
          @echo[3..4].should == [3,4]
        end
      
        it "gets the first element" do
          @echo[0..1].should == [0,1]
        end
    
        it "understands larger ranges" do
          @echo[1..3].should == [1,2,3]
        end
    
        it "stops at the top of the object" do
          @echo[1..7].should == [1,2,3,4]
        end
    
        it "should return [] when start == size" do
          @echo[5..7].should == []
        end

        it "should return nil when start > size" do
          @echo[6..7].should be_nil
        end

        it "should return nil when start before beginning" do
          @echo[-6..7].should be_nil
        end
      end
    
      context "with end == start" do
        (0...5).each do |i|
          it "should get any single element (e.g. #{i})" do
            @echo[i..i].should == [i]
          end
        end
    
        it "should return [] when start == size" do
          @echo[5..5].should == []
        end

        it "should return nil when start > size" do
          @echo[6..6].should be_nil
        end

        it "should return nil when start before beginning" do
          @echo[-6..-6].should be_nil
        end
      end
    
      context "with end < start" do
        (1..5).each do |i|
          it "should return [] for any non-zero element (e.g. #{i})" do
            @echo[i..(i-1)].should == []
          end
        end
      
        it "should return [] for [0..-(size+1)]" do
          @echo[0..-6].should == []
        end
    
        it "should return [] when start == size" do
          @echo[5..4].should == []
        end

        it "should return nil when start > size" do
          @echo[6..5].should be_nil
        end

        it "should return nil when start before beginning" do
          @echo[-6..-7].should be_nil
        end
      end
    end

    context "with exclusive ranges" do
      it "returns all elements" do
        @echo[0...5].should == (0...5).to_a
      end
  
      context "with end > (start+1)" do
        it "understands the boundary case" do
          @echo[3...5].should == [3,4]
        end
      
        it "gets the first element" do
          @echo[0...2].should == [0,1]
        end
    
        it "understands larger ranges" do
          @echo[1...4].should == [1,2,3]
        end
    
        it "stops at the top of the object" do
          @echo[1...8].should == [1,2,3,4]
        end
    
        it "should return [] when start == size" do
          @echo[5...8].should == []
        end

        it "should return nil when start > size" do
          @echo[6...8].should be_nil
        end

        it "should return nil when start before beginning" do
          @echo[-6...8].should be_nil
        end
      end
    
      context "with end == (start+1)" do
        (0...5).each do |i|
          it "should get any single element (e.g. #{i})" do
            @echo[i...(i+1)].should == [i]
          end
        end
    
        it "should return [] when start == size" do
          @echo[5...6].should == []
        end

        it "should return nil when start > size" do
          @echo[6...7].should be_nil
        end

        it "should return nil when start before beginning" do
          @echo[-6...-5].should be_nil
        end
      end
    
      context "with end < (start+1)" do
        (1..5).each do |i|
          it "should return [] for any non-zero element (e.g. #{i})" do
            @echo[i...i].should == []
          end
        end
      
        it "should return [] for [0...-size]" do
          @echo[0...-5].should == []
        end
    
        it "should return [] when start == size" do
          @echo[5...5].should == []
        end

        it "should return nil when start > size" do
          @echo[6...6].should be_nil
        end

        it "should return nil when start before beginning" do
          @echo[-6...-6].should be_nil
        end
      end
    end
  end
  
  context "with index pairs" do
    (0...5).each do |i|
      it "returns a single element if length==1 (e.g. start=#{i})" do
        @echo[i,1] == [i]
      end
    end
    
    it "returns [] if length == 0" do
      @echo[2,0].should == []
    end

    it "returns nil if length < 0" do
      @echo[2,-1].should be_nil
    end
    
    it "understands larger ranges" do
      @echo[1,3].should == [1,2,3]
    end

    it "stops at the top of the object" do
      @echo[1,7].should == [1,2,3,4]
    end

    it "understands negative start indexes" do
      @echo[-3,2].should == [2,3]
    end
    
    it "returns all elements" do
      @echo[0,5].should == (0...5).to_a
    end

    it "should return [] when start == size" do
      @echo[5,2].should == []
    end

    it "should return nil when start > size" do
      @echo[6,2].should be_nil
    end

    it "should return nil when start before beginning" do
      @echo[-6,2].should be_nil
    end
  end
end
