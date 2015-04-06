#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

require 'lib/hyphenator'

WORDS_FILE = "/usr/share/dict/words"
LINE_SIZE = 50

METHODS = %w{moby knuth}

desc "hyphen", "Test loading hyphenation library"
option "method",  :aliases=>'-m', :type=>'string',  :desc=>"Use this method (#{METHODS.join(',')})"
def hyphen
  words = dictionary_words
  format_string = "%-#{LINE_SIZE+20}s"
  timed do
    h = load_hyphenation_library(options[:method])
    100.times do
      w =[]
      while w.join(' ').size < LINE_SIZE
        w << words[rand(words.size)]
      end
      sentence = w.join(' ')
      suffix = h.sentence_suffix(w, sentence.size - LINE_SIZE + '-'.size)
      if suffix==''
        prefix = sentence
      else
        prefix = sentence[0...-(suffix.size)]
        if prefix[-1] == ' '
          prefix = prefix[0...-1]
        else
          prefix += '-'
        end
      end
      puts "#{format_string % sentence} => (#{prefix.size}) #{prefix} | #{suffix}"
    end
  end
end

no_tasks do
  def dictionary_words
    @dictionary_words ||= ::File.read(WORDS_FILE).split("\n")
  end

  def load_hyphenation_library(method)
    Hyphenator.create(method)
  end

  def timed(label='that', &blk)
    start_time = Time.now
    yield
    end_time = Time.now
    warn "#{label} took #{end_time - start_time} seconds"
  end
end