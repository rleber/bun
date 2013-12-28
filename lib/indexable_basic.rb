#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

#  Indexable::Basic
#
#  Adds Array-like capability to any Class, using only two primitives.
#
#  This is designed to add Ruby-like indexing flexibility (e.g. start+length, range, negative indexes) to simple
#  objects which have only basic 0..n indexing. It assumes that the underlying object uses integers as indexes,
#  that indexes are consecutive, and that the first index is zero.
#
#  Required primitives (instance methods):
#
#  #at(index)         # Required  Returns the collection element at the given index (or nil if no such element exists)
#  #size              # Required  The number of elements in the collection (counting nil values within the collection).
#
#  The instance methods are added to the class:
#
#  #[](*args)           Array indexing, including selection by start, start and length, or range. If indexes are 
#                       Numeric and #first_index is non-negative, then positive or negative indexes are supported 
#                       (i.e. negative indexes count backward from the end of the collection -- see #index_backward?)
#
#  #slice               Same as #[]
#
#  index_result(*args)  What type of result would the given arguments result in, if passed to :[]? Possible values
#                       are :scalar, :array. (Note: :[] might also return nil if indexes are out of range -- 
#                       index_result doesn't check this.)
#
#  So, for instance, the following defines Array-like indexing for an arbitrary object
#
#     require 'indexable'
#   
#     class Foo
#       include Indexable
#       attr_accessor :storage
#       
#       # Note: at should return nil i is out of range
#       def at(i)
#         storage.get(i)
#       end
#
#       def size
#         storage.size
#       end
#     end
#
#     frodo = Foo.new
#     frodo[12..-3]
#
#  TODO Include Enumerable, define each etc., if they're not already defined
#  TODO Create more extensive versions of this: e.g. starting other than at zero, non-contiguous indexes, non-numeric indexes
#  TODO Optimization
#  TODO Improve method documentation
#  TODO Bundle as a gem
#  TODO Minimally intrusive logging

module Indexable
  module Basic
    
    def self.included(base)
      base.send(:alias_method, :slice, :[]) if base.instance_methods.include?(:[])
      base.send(:alias_method, :[], :extended_slice)
      base.send(:attr_accessor, :index_array_class)
    end
    
    # Convert an index (which might be negative) to a positive one
    def _normalize_index(ix)
      ix += self.size if ix<0
      ix
    end
    private :_normalize_index

    # Convert an index specification to a range of individual indexes
    # An index specification might be a single index, a (start, length) pair, or
    # a Range. Returns a hash of several values, including:
    #
    #    :arg_type    The type of index arguments given
    #    :result  The type of result that should be calculated
    #    :start   The starting index of the elements to be returned
    #    :end     The ending index of the elements to be returned
    #
    # Type is required in order to properly emulate Ruby behavior. Consider
    # the following examples:
    #
    #   [0,1,2][4..5]  #=> nil
    #   [0,1,2][3..5]  #=> []
    #   [0,1,2][2..5]  #=> [2]
    #   [0,1,2][1..5]  #=> [1,2]
    #   [0,1,2][4]     #=> nil
    #   [0,1,2][2]     #=> 2
    #
    # Argument types returned:
    #
    #   :scalar   A single index
    #   :pair     A start,length pair
    #   :range    A range
    #
    # Result types returned:
    #
    #   :scalar   A single scalar value should be returned
    #   :array    An array should be returned
    #   :empty    An empty array should be returned
    #   :nil      The value nil should be returned
    #
    # For types :scalar and :array, both the starting and ending index
    # are guaranteed to be in the range 0...size, and start <= end

    def normalize_indexes(*args)
      res = _decode_indexes(*args)
      # Normalize negative indexes, relative to the end of the collection
      # Adjust the edge cases
      res = _adjust_result_type(res)
    
      # Ensure that the indexes for arrays are in bounds
      # It's not necessary to check start, because we know that
      # 0 <= start < size (or type would be :nil or :empty).
      # It's not necessary to check scalars, because scalars always have 
      # start==end, and therefore 0 <= end < size from the above.
      # It's not necessary to check that end >= 0 because we know that
      # end >= start (or type would be :nil or :empty)
      if res[:result]==:array 
        res[:end] = size-1 if res[:end] >= size
      end
      res
    end
  
    # Convert an index of whatever form to :arg_type, :restul, :start, and :end
    def _decode_indexes(*args)
      res = case args.size
      when 1
        ix = args.first
        if ix.is_a?(Range)
          finish = _normalize_index(ix.end)
          finish -= 1 if ix.exclude_end?
          {:arg_type=>:range, :args=>args, :result=>:array, :start=>_normalize_index(ix.begin), :end=>finish, :exclusive=>ix.exclude_end?}
        else
          ix = _normalize_index(ix)
          {:arg_type=>:scalar, :args=>args, :result=>:scalar, :start=>ix, :end=>ix}
        end
      when 2
        start, length = args
        start = _normalize_index(start)
        {:arg_type=>:pair, :args=>args, :result=>:array, :start=>start, :end=>start + length - 1}
      else
        raise ArgumentError, "wrong number of arguments: #{args.size} for 1 or 2"
      end
      res
    end
    private :_decode_indexes
    
    def index_result(*args)
      {:range=>:array, :pair=>:array, :scalar=>:scalar}[_decode_indexes(*args)[:arg_type]]
    end
  
    # Check indexes, and determine result type, taking into count
    # all the quirky Ruby edge cases
    def _adjust_result_type(res)
      res = res.dup
      case res[:start]<=>size
      when 1 # Start index is beyond the end of the range
        res[:result] = :nil
      when 0 # Start index == collection size
        res[:result] = res[:result]==:array ? :empty : :nil
      else # Start index < collection size
        # Note: not necessary to check this in other cases, because
        # in those cases start >= size >= 0
        if res[:start] < 0
          res[:result] = :nil
        end
      end
      case res[:end] <=> (res[:start]-1)
      when -1 # End index < start index-1
              # Note, since start!=end, type can't be :scalar
        res[:result] = :nil if res[:arg_type]==:pair
      when 0 # End index == start-1 (zero length)
        # Note: Can't be :scalar, because end!=start
        res[:result] = :empty unless res[:result] == :nil
      end
      res
    end
    private :_adjust_result_type
  
    # Define generalized indexing in terms of at(i)
    def extended_slice(*args)
      @index_range = normalize_indexes(*args)
      case @index_range[:result]
      when :nil
        return nil
      when :empty
        return []
      end
      res = (@index_range[:start]..@index_range[:end]).map {|i| at(i) }
      @index_range[:class] = self.class.name
      if @index_range[:result] == :scalar
        res = res.first 
      else
        klass = self.index_array_class || self.class
        @index_range[:array_class] = klass.name
        res = klass.new(res)
      end
      log if $indexable_basic_log
      res
    end
    
    def log_file
      ENV['HOME'] + '/.indexable_basic.log'
    end

    $indexable_basic_log = false
    def log
      return unless $indexable_basic_log
      File.open(log_file, 'a') {|f| f.puts @index_range.inspect + "\n"}
    end
    
    def index_range
      @index_range
    end
  end
end