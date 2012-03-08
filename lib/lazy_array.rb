# A lazy array

require 'lib/indexable_basic'

class LazyArray < Array
  alias_method :index_before_lazy_array, :[]
  alias_method :set_before_lazy_array, :[]=

  include Indexable::Basic
  
  attr_accessor :size
  
  def initialize(spec=0, obj=nil, &blk)
    super()
    @size = 0
    if spec.is_a?(Array)
      spec.each {|v| self << v }
    elsif obj.nil?
      @size = spec
    else
      size.times { self << obj }
    end
    @value_block = blk
  end
  
  def at(index)
    if v = self.index_before_lazy_array(index)
      v.first
    elsif @value_block
      self[index] = v = @value_block.call(index)
      v
    else
      nil
    end
  end
  
  # Necessary, so we can have nils in the array
  # TODO Extended assignment indexing
  def []=(index, value)
    @size = index + 1 if index >= size
    super(index, [value, true])
    value
  end
  
  def <<(value)
    self[@size] = value
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
end