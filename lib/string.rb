#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

require 'digest/md5'
require 'tempfile'

class String
  class InvalidCheck < ArgumentError; end

  def escaped
    self.inspect[1..-2]
  end
  
  class Trait; end # Defined elsewhere
  
  VALID_CONTROL_CHARACTER_HASH = {
    line_feed:       "\n", 
    carriage_return: "\r", 
    backspace:       "\x8", 
    tab:             "\x9", 
    vertical_tab:    "\xb",
    form_feed:       "\xc",
  }
  VALID_CONTROL_CHARACTER_HASH.each do |key, value|
    const_set(key.upcase, value)
    const_set("#{key.upcase}_REGEXP", /#{value.escaped}/)
  end

  VALID_CONTROL_CHARACTER_ARRAY = VALID_CONTROL_CHARACTER_HASH.values
  VALID_CONTROL_CHARACTER_STRING = VALID_CONTROL_CHARACTER_ARRAY.join
  VALID_CONTROL_CHARACTERS = VALID_CONTROL_CHARACTER_STRING.escaped
  VALID_CONTROL_CHARACTER_REGEXP = /[#{VALID_CONTROL_CHARACTERS}]/
  INVALID_CHARACTER_REGEXP = /(?!(?>#{VALID_CONTROL_CHARACTER_REGEXP}))[[:cntrl:]]/
  VALID_CHARACTER_REGEXP = /(?!(?>#{INVALID_CHARACTER_REGEXP}))./

  class << self

    def valid_control_character_array
      VALID_CONTROL_CHARACTER_ARRAY
    end

    def valid_control_character_hash
      VALID_CONTROL_CHARACTER_HASH
    end

    def valid_control_character_regexp
      VALID_CONTROL_CHARACTER_REGEXP
    end

    def invalid_character_regexp
      INVALID_CHARACTER_REGEXP
    end

    def valid_character_regexp
      VALID_CHARACTER_REGEXP
    end

    # CHECK_TESTS = {
    #   tabbed: {
    #     options: [:tabs, :no_tabs],
    #     description: "File contains tabs",
    #     test: lambda {|text| text.tabbed? ? :tabs : :no_tabs }
    #   },
    #   overstruck: {
    #     options: [:tabs, :no_tabs],
    #     description: "File contains backspaces",
    #     test: lambda {|text| text.overstruck? ? :overstruck : :not_overstruck }
    #   },
    #   
    # }
    
  end

  
  def legibility
    String::Check(self, :readability)
  end
  
  def counts(*character_sets)
    counter = String::Trait::Base.new(self, character_sets)
    counter.counts
  end
  
  def count_hash(*character_sets)
    counter = String::Trait::Base.new(self, character_sets)
    counter.character_counts
  end

  def clean?
    self.force_encoding('ascii-8bit') !~ String.invalid_character_regexp
  end
  
  def tabbed?
    self.force_encoding('ascii-8bit') =~ /\x9/
  end
  
  def overstruck?
    self.force_encoding('ascii-8bit') =~ /\x8/
  end
  
  def trait(analysis, options={})
    examiner = String::Trait.create(analysis, options)
    examiner.attach :string, self
    examiner
  end
  
  # Options should include :file, :path, :expression
  def expression(options=[])
    evaluator = Bun::Expression.new(options)
    evaluator.data = self
    evaluator
  end
  
  def titleize
    split(/(\W)/).map(&:capitalize).join
  end

  def underscore
    self.gsub(/::/, '/').
         gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
         gsub(/([a-z\d])([A-Z])/,'\1_\2').
         tr("-", "_").
         downcase
  end

  def camel_case
  return self if self !~ /_/ && self =~ /[A-Z]+.*/
  split('_').map{|e| e.capitalize}.join
  end

  # Convert a string to its equivalent character set, e.g.
  # e.g. "abbbasssscc".positive_character_set => '[a-cs]'
  # Thanks to https://gist.github.com/melborne/1573258 for the idea that inspired this refactoring (i.e. using chunk)
  def character_set(options={})
    groups = self.dup
                 .force_encoding('ascii-8bit')
                 .split(//) # Split into individual characters
                 .map {|ch| (options[:case_insensitive] ? downcase(ch) : ch).ord } # Convert to ASCII codes
                 .inject([]) {|ary, n| ary[n] = n; ary } # Convert to a membership array (ary[i]=i iff i is in string)
                 .chunk {|n| n.nil? ? nil : n.chr.character_type(flag_dashes: true) } # The clever bit: chunk removes chunks labelled nil
                 .to_a
    contains_dash = false
    if options[:single_as_string] || (groups.size==1 && groups.first.size==1)
      char = groups.first[1].first.chr
      encoding = char.printable
    else
      encoding = groups.map {|typ, group| [typ, group.map{|n| n.chr}.join]}
                       .map {|typ, group| 
                              case typ
                              when :other
                                group.set_escaped
                              when :dash
                                contains_dash = true
                                next
                              else
                                group.size > 1 ? group.minimal_set_encoding : group.set_escaped
                              end
                            }
                       .compact
                       .join
      encoding = '-' + encoding if contains_dash
      delimiters = (options[:delimiters]||'[]').make_delimiters
      encoding = "#{delimiters[0]}#{encoding}#{delimiters[1]}"
    end
    encoding
  end

  # Identify character type of a character
  # Only uses the first character
  # Option :flag_dashes separates '-' into its own class (which is useful for set encoding)
  def character_type(options={})
    case self.escaped
    when /^\\x/
      :control
    when /^[a-zA-Z0-9]/
      :alphanumeric
    when '-'
      options[:flag_dashes] ? :dash : :other
    else
      :other
    end
  end

  # Return whichever is shorter, the a-z or abc encoding for a group of characters
  # CAREFUL: Assumes string is actually a valid group. so "AbcdE".minimal_set_encoding => 'A-E'
  def minimal_set_encoding
    res1=self.hyphenated_set_encoding
    res2=self.set_escaped
    res1.size < res2.size ? res1 : res2
  end

  # Return the hyphenated set encoding for a string
  # CAREFUL: Assumes string is actually a valid group. so "AbcdE".hyphenated_set_encoding => 'A-E'
  def hyphenated_set_encoding
    "#{self[0].set_escaped(no_ctrl: true)}-#{self[-1].set_escaped(no_ctrl: true)}"
  end

  # Splits a delimiter specification into an array of [opening_delimiter, closing_delimiter]
  # Assumes string is 0-2 characters (ignores the rest)
  #   "".make_delimiters => ['','']
  def make_delimiters
    ((self).split(//)*2+['',''])[0,2] # *2 doubles up single delimiters
  end
  
  def safe
    if self =~ /^[\w\d.\/]*$/
      self.dup
    else
      self.inspect
    end
  end
  
  def escaped
    inspect[1..-2]
  end

  def printable
    quote_for = []
    escaped = self.split(//)
                  .map {|ch|
                         case ch
                         when ' ','"',"'"
                           quote_for << ch
                           ch
                         else
                           ch.escaped
                         end
                       }
                  .join
    quotes = case quote_for.uniq.sort.join
    when '','"',"'" # No quotes
      ['','']
    when " ",' "'
      ["'","'"] # Single quotes
    when " '"
      ['"', '"'] # Double quotes
    else
      ['%q{', '}'] # Maximum quotes
    end
    quotes[0] + escaped + quotes[1]
  end
  
  # Escaping for use inside ranges, e.g. a-z
  def set_escaped(options={})
    self.split(//).map do |ch|
      res = ch.escaped
      res = "\\x#{'%02X' % ch.ord}" if options[:no_ctrl] && res=~/^\\\w$/
      res.gsub("-",'\\-')
    end.join
  end

  def digest
    Digest::MD5.hexdigest(self).inspect[1..-2] # Inspect prevents YAML from treating this as binary
  end

  def to_hex
    unpack('H*').first
  end
  
  def freeze_for_thor
    self.gsub("\n","\n\005").gsub(' ',"\177")
  end
  
  def scrub(options={})
    column_width = options[:column_width] || 80
    column_margin = options[:column_margin] || 20
    tabs = options[:tabs] || [column_width + column_margin]
    text = self.dup
    text.gsub!(/_\x8/,'') # Remove underscores
    text.gsub!(/(.)(?:\x8\1)+/,'\1') # Remove bolding
    text.gsub!(/\xC/, options[:form_feed]||'') # Remove form feeds
    text.gsub!(/\xB/, options[:vertical_tab]||'') # Remove vertical tabs
    text.gsub!(/[[:cntrl:]&&[^\n\x8]]/,'') # Remove other control characters
    t = Tempfile.new('string_scrub')
    t.write(text)
    t.close
    tab_option = tabs.map{|t| t.to_s}.join(',')
    %x{cat #{t.path} | expand -t #{tab_option}}
  end

end

require 'lib/trait'
require 'lib/bun/expression'
