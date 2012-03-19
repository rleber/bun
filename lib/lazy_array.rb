#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# A lazy array

require 'lib/indexable_basic'

# TODO Much simpler ProxyArray class without extended indexing

class LazyArray

  include Indexable::Basic
  include Comparable
  
  attr_accessor :size
  
  def initialize(spec=0, obj=nil, &blk)
    @size = 0
    @values = Array.new
    if spec.is_a?(Array)
      spec.each {|v| self << v }
    elsif obj.nil?
      @size = spec
    else
      spec.times { self << obj }
    end
    @value_block = blk
  end
  
  def at(index)
    if v = @values[index]
      v.first
    elsif @value_block
      v = @value_block.call(index)
      @values[index] = [v, true]
      v
    else
      nil
    end
  end
  
  # Necessary, so we can have nils in the array
  # TODO Extended assignment indexing
  def []=(index, value)
    @size = index + 1 if index >= size
    @values[index] = [value, true]
    value
  end
  
  def <<(value)
    @values[@size] = [value, true]
    @size += 1
    self
  end
  
  def +(other)
    res = self.dup
    other.each {|v| res << v}
    res
  end
  
  # TODO Indexable should define first, last
  def first
    self[0]
  end
  
  def last
    self[-1]
  end
  
  def to_a
    (0...@size).map {|i| self[i] }
  end
  
  def <=>(other)
    self.to_a <=> other.to_a
  end
  
  def method_missing(meth, *args, &blk)
    to_a.send(meth, *args, &blk)
  rescue NoMethodError
    raise NoMethodError, "#{self.class}##{meth} method not defined"
  end
end