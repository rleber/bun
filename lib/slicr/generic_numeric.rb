#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

class GenericNumeric
  include Comparable

  def initialize(value)
    @data = value
  end

  def to_int
    @data
  end
  alias_method :to_i, :to_int
  
  def value
    @data
  end
  
  def internal_value
    @data
  end
  protected :internal_value
  
  def inspect
    "<#{self.class}: #{internal_value.inspect}>"
  end
  
  def <=>(other)
    case other
    when GenericNumeric
      self.value <=> other.value
    when Numeric
      self.value <=> other
    else
      raise TypeError, "Can't compare #{self.class} with #{other.class}"
    end
  end
  
  def method_missing(name, *args, &blk)
    ret = begin
      @data.send(name, *args, &blk)
    rescue NoMethodError
      raise NoMethodError, "#{self.class}##{name} method not defined"
    end
    ret.is_a?(Numeric) ? self.class.new(ret) : ret
  end
end