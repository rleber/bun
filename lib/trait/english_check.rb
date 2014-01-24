#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Calculate proportion of english words

require 'lib/trait/numeric'

class String
  class Trait
    module EnglishCheck
      
      # TODO Handle root words (e.g. having, have) more intelligently
      # TODO Refactor using ffi-aspell
      # TODO Put this in config
      DICTIONARY_FILE = '/usr/share/dict/words'

      @@dictionary = nil
      
      def self.included(base)
        base.extend(ClassMethods)
      end
      
      module ClassMethods
        def dictionary
          @@dictionary ||= ::File.read(DICTIONARY_FILE)
                             .chomp
                             .split("\n")
                             .inject({}) {|hsh, word| w = word.strip.downcase; hsh[w] = true; hsh }
        end
      
        def dictionary_add(word)
          @@dictionary ||= self.dictionary
          @@dictionary[word.downcase] = true
        end
      end
      
      def dictionary
        self.class.dictionary
      end
      
      def _is_english?(word)
        word && dictionary[word.downcase]
      end
      private :_is_english?
            
      def is_english?(word)
        word = word.strip
        if _is_english?(word)
          true
        else
          tests = [
            word =~ /^\d+(\.\d+)?$/, # Number
            word =~ /^[A-Z][a-z]{2,}/, # Possible proper name
            word =~ /[a-z]{3,}s$/i && _is_english?(word[0..-2]), # Plural?
            word =~ /[a-z]{2,}ies$/i && _is_english?(word[0..-4]+'y'), # Plural?
            word =~ /[a-z]{2,}ses$/i && _is_english?(word[0..-3]), # Plural?
            word =~ /[a-z]{2,}ses$/i && _is_english?(word[0..-4]), # Plural?
            word =~ /[a-z]{2,}(ed|es)$/i && _is_english?(word[0..-2]),
            word =~ /[a-z]{2,}(ed|es)$/i && _is_english?(word[0..-3]),
            word =~ /[a-z]{1,}[bcdfgklmnoprstuvz]ing$/i && _is_english?(word[0..-4]+'e'),
            word =~ /[a-z]{2,}[achjkouvwx](ed|ing|able)$/i && _is_english?(word[0..-($1.size + 1)]),
            word =~ /[a-z]{2,}[bdlmnprstz](ed|ing|able)$/i && _is_english?(word[0..-($1.size + 1)]),
            word =~ /[a-z]{2,}[bdlmnprstz](ed|ing|able)$/i && _is_english?(word[0..-($1.size + 2)]),
            word =~ /[a-z]{2,}ying$/i && _is_english?(word[0..-4]),
            word =~ /[a-z]{2,}ied|ies$/i && _is_english?(word[0..-4]+'y'),
            word =~ /[a-z]{2,}tion$/i && _is_english?(word[0..-5]+'e'),
          ]
          res = tests.any? {|test| test }
          self.class.dictionary_add(word) if res
          res
        end
      end
    end
  end
end

