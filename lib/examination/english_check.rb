#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Calculate proportion of english words

require 'lib/examination/numeric'

class String
  class Examination
    module EnglishCheck
      
      # TODO Handle root words (e.g. having, have) more intelligently
      # TODO Refactor using ffi-aspell
      # TODO Put this in config
      LIBRARY_FILE = '/usr/share/dict/words'

      def library
        @library ||= ::File.read(LIBRARY_FILE)
                           .chomp
                           .split("\n")
                           .inject({}) {|hsh, word| w = word.strip.downcase; hsh[w] = true; hsh }
      end
      
      def _is_english?(word)
        word && library[word.downcase]
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
          tests.any? {|test| test }
        end
      end
    end
  end
end

