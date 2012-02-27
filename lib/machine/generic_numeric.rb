class GenericNumeric

  def initialize(value)
    @data = value
  end

  def to_int
    @data
  end
  
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
  
  def method_missing(name, *args, &blk)
    ret = @data.send(name, *args, &blk)
    ret.is_a?(Numeric) ? self.class.new(ret) : ret
  end
end
