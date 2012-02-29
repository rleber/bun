require 'machine/word'

# TODO Get this working

module Machine
  
  def self.Block(constituent_class)
    klass = Class.new(MultiWordBase)
    klass.contains constituent_class
    klass.word_size = constituent_class.size
    klass
  end

  class MultiWordBase < Word
    include Container
    
    class << self
      attr_accessor :word_size
    end
    
    def get_at(*args)
      @data.[](*args)
    end
    
    def set_at(*args)
      @data.[]=(*args)
    end

    def self.word_size
      constituent_class.size
    end
    
    def word_size
      self.class.word_size
    end
    
    def size
      @data.size * word_size
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
      words = (from_word..to_word).map {|i| self[i] }
      words[0] &= constituent_class.strip_leading_bit_masks[from_bit]
      words[-1] &= constituent_class.strip_trailing_bit_masks[to_bit]
      words.inject {|val, word| val<<word_size | word }
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

    def get_slice(n, size, offset=0)
      size = index_numeric(size)
      offset = index_numeric(offset)
      start = (n-1)*size + offset
      get_bits(start, start+size-1)
    end
  end
end