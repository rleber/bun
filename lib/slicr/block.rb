require 'slicr/word'

# TODO Get this working

module Slicr
  
  def self.Block(constituent_class)
    klass = Class.new(Words(constituent_class))
    class << klass
      def inherited(subclass)
        puts "#{subclass} inheriting #{self}"
        subclass.send :include, Slicr::Sliceable
        subclass.send :include, Slicr::BlockBase
        subclass.send :define_format, :inspect, '%p'
      end
    end
    klass
  end

  module BlockBase
    
    def self.included(base)
      base.extend ClassMethods
    end
    
    module ClassMethods
      def word_size
        constituent_class.width
      end
    end
    
    def word_size
      self.class.word_size
    end
    
    def width
      self.size * word_size
    end
    
    def decode_index(index)
      index.split(":").map{|segment| segment.to_i}
    end
    
    def encode_index(*segments)
      segments.flatten.map{|segment| segment.to_s}.join(':')
    end

    # Indexes may be specified in one of three ways: as a bit number,
    # as a [word, bit] pair, or as a string "word:bit"
    def index_numeric(*index)
      index = index.flatten
      index = index.first if index.size == 1
      case index
      when Numeric
        index
      when Array
        index[0]*word_size + index[1]
      when String
        index_numeric(index_array(index))
      else
        raise IndexError, "Unknown index type (#{index.inspect})"
      end
    end
    
    def index_string(*index)
      index = index.flatten
      index = index.first if index.size == 1
      case index
      when Numeric
        index_string(index_array(index))
      when Array
        encode_index(*index)
      when String
        index
      else
        raise IndexError, "Unknown index type (#{index.inspect})"
      end
    end
    
    def index_array(*index)
      index = index.flatten
      index = index.first if index.size == 1
      case index
      when Numeric
        index.divmod(word_size)
      when Array
        index
      when String
        decode_index(index)
      else
        raise IndexError, "Unknown index type (#{index.inspect})"
      end
    end
    
    def index_class(klass, *index)
      case klass
      when Numeric
        index_numeric(*index)
      when Array
        index_array(*index)
      when String
        index_string(*index)
      else
        raise IndexError, "Unknown index type (#{index.inspect})"
      end
    end
    
    def bit_segment(from, to)
      from_word, from_bit = index_array(from)
      to_word, to_bit = index_array(to)
      puts "bit_segment: from_word=#{from_word.inspect}, from_bit=#{from_bit.inspect}, to_word=#{to_word.inspect}, to_bit=#{to_bit.inspect}"
      words = (from_word..to_word).map {|i| self[i] }
      masks = constituent_class.ones_masks
      words[0] &= masks[word_size - from_bit]
      words[-1] &= (masks[word_size] ^ masks[word_size - to_bit - 1])
      puts "words=#{words.map{|w| '%012o' % w}.inspect}"
      res = words.inject {|val, word| val<<word_size | word }
      puts "res=#{'%024o' % res}"
      res
    end

    def get_bits(from, to)
      to_word, to_bit = index_array(to)
      bit_segment(from, to) >> bit_count(to_bit, word_size-1)
    end
    
    def bit_count(from, to)
      index_numeric(to) - index_numeric(from) + 1
    end
    
    def increment_index(index, increment)
      index_class(index, index_numeric(index)+1)
    end

    def get_slice(n, slice_size, offset=0, gap=0, width=nil)
      slice_size = index_numeric(slice_size)
      width ||= self.width
      offset = index_numeric(offset)
      gap = index_numeric(gap)
      width = index_numeric(width)
      start = (n-1)*(slice_size + gap) + offset
      finish = start+slice_size-1
      puts "#{self.class}#slice: n=#{n}, start=#{start.inspect}, finish=#{finish.inspect}"
      get_bits(start, finish)
    end
    
    def value
      self.to_a
    end
  end
end