#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

#  Indexable::Simple
#
#  Adds Array-like capability to any Class, using only a few primitives
#
#  Required primitives (instance methods):
#
#  #at(index)         # Required  Returns the array element at the given index (or nil if no such element exists)
#  #succ_index(index) # Optional  Returns the next index after the given one. (If not provided, Integer#succ is used.)
#  #first_index       # Optional  The lowest index in the array. If not provided (nor #index_range), zero is assumed.
#  #size              # Optional  The size of the array. If not provided, it is calculated.
#  #last_index        # Optional  The highest index in the array. If not provided (nor #index_range), it is calculated.
#  #index_range       # Optional  The range of indexes in the array. If not provided, it is calculated.
#  #consecutive?      # Optional  Are the indexes of the array consecutive? (Assumed true, unless specified otherwise.)
#  #valid_index?(i)   # Optional  Is i a valid index for the array. (Assumed true unless specified otherwise.)
#  
#  Note that if none of last_index, index_range, or size are provided, Indexable::Simple will create iterators and'
#  calculate array size by assuming that there are no nil entries in the array -- that is, the first time at(index)
#  returns nil, that will be assumed to be the end of the array.
#
#  The instance methods are added to the class:
#
#  #[]                  Array indexing, including selection by start, start and length, or range. If indexes are 
#                       Numeric and #first_index is non-negative, then positive or negative indexes are supported 
#                       (i.e. negative indexes count backward from the end of the array -- see #index_backward?)
#
#  #slice               Same as #[]
#
#  #size                The number of entries in the array
#
#  #length              Same as #size
#
#  #index_range         The range of indexes in the array, from lowest to highest. See also #includes_index?
#
#  #indexes             An Array of the indexes in the array, in order. Note that it is not true that if #index_range
#                       includes an index, that index will also be in included in #indexes, because it is not required
#                       that indexes be consecutive. Nor is it true that if array#index_range includes and index (say
#                       index i), then array[i] != nil, because nil elements are permitted.
#                       
#  #index_backward?     True if and only if the array supports indexing backward by negative indexes.
#
#  #each                Standard enumerator. Yields each element in turn.
#
#  #each_index          Index enumerator. Yields each index in turn
#  
#  #each_with_index     Enumerator yielding elements and their indexes
#
#  #set_at(i,value)     Sets the element of the array at index i to the given value
#
#  Numerous other methods are provided (e.g. select, any?, etc.) by including Enumerable. Others can be emulated
#  by converting the array to a standard Ruby Array, using the :to_a method.
# 
#  So, for instance, the following defines a fully capable readonly Array-like class, where elements are stored in every second element of @storage:
#
#     require 'indexable'
#   
#     class Foo
#       include Indexable
#       attr_accessor :storage
#       
#       # Note: at should return nil i is out of range
#       def at(i)
#         storage[2*i]
#       end
#
#       def size
#         (storage.size+1).div(2)
#       end
#     end
#    
#    bar = Foo.new
#    bar.storage = Array.new
#    bar[1] = 'frodo'
#    puts bar.inspect                    # => [nil, nil, "frodo"]
#    puts bar.size                       # => 2
#    puts bar.to_a.inspect               # => [nil, "frodo"]
#    puts bar.map {|e| e.to_s}.join(',') # => ,frodo

module Indexable
  module Simple
    # Convert an index (which might be negative) to a positive one
    def _convert_index(ix)
      _ensure_numeric_argument(ix, "index")
      ix = (self.size+ix) if ix<0
      ix
    end
    private :_convert_index
  
    def _ensure_numeric_argument(ix, label)
      raise TypeError, "Non-numeric #{label} #{ix.inspect} for #{self.class}" unless ix.is_a?(Fixnum)
    end
  
    # Convert an index specification to a range of individual indexes
    # An index specification might be a single index, a (start, length) pair, or
    # a Range
    def _convert_indexes(*args)
      indexes = case args.size
      when 1
        ix = args.first
        if ix.is_a?(Range)
          [ix.begin, ix.end + (ix.exclude_end? ? -1 : 0)]
        else
          [ix, ix]
        end
      when 2
        start, length = args
        start = _convert_index(start)
        [start, start + length - 1]
      else
        raise ArgumentError, "wrong number of arguments: #{args.size} for 1 or 2"
      end
      indexes = indexes.map {|ix| _convert_index(ix) }
      (indexes.first..indexes.last)
    end
  
    # Define generalized indexing in terms of at(ix)
    def [](*args)
      range = _convert_indexes(*args)
      # Handle special cases
      return nil if range.begin < 0 || range.begin > self.size
      range.end = Range.new(range.begin, self.size-1) if range.begin >= self.size
      range.map{|ix| self.at(ix) }
    end
    
    def each
      index = 
      size.times.do |i|
        yield at(index)
    end
  
    REQUIRED_METHODS = [:size, :at]
    def self.included(base)
      base.send :alias_method :slice, :[]
      base.send :alias_method :length, :size
      REQUIRED_METHODS.each do |m|
        raise "Cannot include Indexable in #{base}: #{base}##{m} method not defined" unless base.method_defined?(m)
      end
    end
  end
end