module Slicr
  class Cache
    def initialize(&blk)
      warn caller.join("\n")
      exit
      @contents = []
      @calculator = blk
    end
    
    # TODO Generalize indexing
    def [](n)
      @contents[n] ||= _calculate(n)
    end
    
    def []=(n, value)
      @contents[n] = value
    end
    
    def _calculate(n)
      @calculator ? @calculator.call(n) : n
    end
    private :_calculate
    
    def size
      @contents.size
    end
  end
end