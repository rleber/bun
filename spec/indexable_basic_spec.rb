#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

class Echo
  include Indexable::Basic
  include Comparable
  
  def initialize(defn=nil)
    case defn
    when nil
      @values = []
      @size = 0
    when Array
      @values = defn
      @size = @values.size
    else
      @size = defn
      @values = nil
    end
  end
  
  def at(ix)
    @values ? @values[ix] : ix
  end
  
  def size
    @size
  end
  
  def to_a
    @values || (0...size).to_a
  end
  
  def <=>(other)
    self.to_a <=> other.to_a
  end
end
    

shared_examples "indexable is indexed" do |object, expected_values|
  size = expected_values.size
  
  it "should allow indexing" do
    object.should respond_to :[]
  end
  
  context "should retrieve single indexes" do
  
    context "should return nil out of range" do
      it "should return nil for self[#{size}]" do
        object[size].should be_nil
      end

      it "should return nil for self[#{-(size+1)}]" do
        object[-(size+1)].should be_nil
      end
    end
    
    context "with positive values" do
      size.times do |i|
        it "should retrieve self[#{i}]" do
          object[i].should == expected_values[i]
        end
      end
    end
  
    context "with negative single values" do
      size.times do |i|
        it "should retrieve self[#{i-size}]" do
          object[i-size].should == expected_values[i]
        end
      end
    end
  end
  
  context "should retrieve index ranges" do
    context "with inclusive ranges" do
      [false, true].each do |negative_i|
        [false, true].each do |negative_j|
          context "with #{negative_i ? 'negative' : 'positive'}..#{negative_j ? 'negative' : 'positive'}" do
            (-(size+1)..(size+1)).each do |i|
              next if (negative_i && i >= 0) || (!negative_i && i<0)
              (-(size+1)..(size+1)).each do |j|
                next if (negative_j && j >= 0) || (!negative_j && j<0)
                it "should retrieve self[#{i}..#{j}]" do
                  object[i..j].should == expected_values[i..j]
                end
              end
            end
          end
        end
      end
    end
    
    context "with exclusive ranges" do
      [false, true].each do |negative_i|
        [false, true].each do |negative_j|
          context "with #{negative_i ? 'negative' : 'positive'}...#{negative_j ? 'negative' : 'positive'}" do
            (-(size+1)..(size+1)).each do |i|
              next if (negative_i && i >= 0) || (!negative_i && i<0)
              (-(size+1)..(size+1)).each do |j|
                next if (negative_j && j >= 0) || (!negative_j && j<0)
                it "should retrieve self[#{i}...#{j}]" do
                  object[i...j].should == expected_values[i...j]
                end
              end
            end
          end
        end
      end
    end
  end
  
  context "with start,length pairs" do
    [false, true].each do |negative_i|
      context "with #{negative_i ? 'negative' : 'positive'} start index" do
        (-(size+1)..(size+1)).each do |i|
          next if (negative_i && i >= 0) || (!negative_i && i<0)
          (-1..(size+1)).each do |l|
            it "should retrieve self[#{i},#{l}]" do
              object[i,l].should == expected_values[i,l]
            end
          end
        end
      end
    end
  end
end

describe Indexable::Basic do
  before do
    @echo = Echo.new(5)
  end
  
  $echo = Echo.new(5)
  
  include_examples "indexable is indexed", $echo, Echo.new((0...5).to_a)
end