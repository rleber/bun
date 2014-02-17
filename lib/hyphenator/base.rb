#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Classes for hyphenationx


module Hyphenator
  class << self
    def create(method, *args)
      case method.to_s.downcase
      when 'moby'
        Hyphenator::Moby.new(*args)
      when 'knuth'
        Hyphenator::KnuthLiang.new(*args)
      else
        raise ArgumentError, "Unknown hyphenator type: #{method.inspect}"
      end
    end
  end

  class Base
    DEFAULT_MINIMUM_HYPHENATED_CHUNK_SIZE = 2

    attr_reader :longest_key
    attr_writer :minimum_chunk_size

    def load
    end

    def minimum_chunk_size
      @minimum_chunk_size ||= DEFAULT_MINIMUM_HYPHENATED_CHUNK_SIZE
    end

    def hyphenate(word)
      raise RuntimeError, "Class #{self.class} does not define hyphenate method"
    end

    def allows_multiple_words?
      false
    end

    def sentence_suffix(words, minimum_size=2)
      load # Ensure dictionary is loaded
      min_size = [minimum_size,minimum_chunk_size].max
      chunk = ''
      words.size.times do |i|
        next_word = words[-(i+1)]
        break unless next_word =~ /^[A-Za-z]+$/
        chunk = next_word + (i==0 ? '' : ' '+chunk)

        defn = hyphenate(chunk)
        if defn.size>1
          suffix = ''
          defn.reverse.each do |syllable|
            break if suffix.size >= minimum_size
            suffix = syllable + suffix
          end
          return suffix
        end
        return chunk if chunk.size >= min_size
        break if chunk.size >= longest_key
        break unless allows_multiple_words?
      end
      ''
    end
  end
end
