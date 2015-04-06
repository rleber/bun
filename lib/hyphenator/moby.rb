#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

module Hyphenator
  class Moby < Base
    # TODO Archive this: It isn't really used
    HYPHENATION_LIBRARY = File.join(Bun.project_path(__FILE__), "data/mhyph/mhyph.txt")
    HYPHENATION_MARKER = "\xA5"

    attr_reader :longest_key

    def dictionary
      load_dictionary unless @dictionary
      @dictionary
    end
    alias_method :load, :dictionary


    def hyphenate(word)
      defn = dictionary[word]
      defn ? defn : [word]
    end

    def allows_multiple_words?
      true
    end

    def load_dictionary
      @longest_key = 0
      @dictionary = ::File.read(HYPHENATION_LIBRARY)
                      .force_encoding('ascii-8bit')
                      .split(/\r\n|\n\r|\r|\n/)
                      .inject({}) {|hsh, entry| 
                            key = entry.gsub(HYPHENATION_MARKER,'')
                            key_size = key.size
                            @longest_key = key_size if @longest_key < key_size
                            hsh[key] = entry.split(HYPHENATION_MARKER)
                            hsh
                          }
    end
    private :load_dictionary
  end
end
