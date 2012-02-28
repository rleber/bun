module Machine
  class Cache
    def initialize(&blk)
      @contents = []
      @calculator = blk
    end
    
    def [](n)
      @contents[n] ||= _calculate(n)
    end
    
    def _calculate(n)
      @calculator ? @calculator.call(n) : n
    end
    private :_calculate
  end
end