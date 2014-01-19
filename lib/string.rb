#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

require 'digest/md5'

class String
  class InvalidCheck < ArgumentError; end

  def escaped
    self.inspect[1..-2]
  end
  
  class Examination; end # Defined elsewhere
  
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
    counter = String::Examination::Base.new(self, character_sets)
    counter.counts
  end
  
  def count_hash(*character_sets)
    counter = String::Examination::Base.new(self, character_sets)
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
  
  def examination(analysis, options={})
    examiner = String::Examination.create(analysis, options)
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
  
  # Convert a string to its equivalent character set, e.g.
  # e.g. "abbbasssscc".positive_character_set => '[a-cs]'
  def character_set(options={})
    s = options[:case_insensitive] ? self.downcase : self
    chars = s.dup.force_encoding('ascii-8bit').split(//).sort.uniq
    runs = [{from: '', to: ''}]
    last_asc = -999
    last_runnable = false
    chars.each do |ch|
      ch_asc = ch[0].ord
      ch_runnable = ch.escaped=~/^\\x|^[a-zA-Z0-9]/
      if !ch_runnable ||
         !last_runnable ||
         ch =~ /[aA0\x00]/ ||  # Don't allow a-z to run into A-Z, etc.
         ch_asc != last_asc + 1
        runs << {:from=>ch, to: ch}
      else # Add to a run
        runs[-1][:to] = ch
      end
      last_asc = ch_asc
      last_runnable = ch_runnable
    end
    runs_string = runs.map do |run|
      from = run[:from]
      to = run[:to]
      if from==to
        from.set_escaped
      else
        res1="#{from.set_escaped(no_ctrl: true)}-#{to.set_escaped(no_ctrl: true)}"
        res2=(from..to).map {|ch| ch.set_escaped(no_ctrl:true)}.join
        res1.size < res2.size ? res1 : res2
      end
    end.join
    runs_string = "-#{$1}#{$2}" if runs_string =~ /(.*)\\-(.*)/
    runs_string = "#{$1}^" if runs_string =~ /^\^(.*)/
    
    delimiters = parse_character_set_delimiters(options[:delimiters])
    if runs_string.size > 1 || !options[:single_as_string]
      runs_output = delimiters[0] + 
                    runs_string + 
                    delimiters[1]
    else
      runs_output = runs_string =~ /\s/ ? runs_string.inspect : runs_string
    end
    runs_output
  end
  
  def parse_character_set_delimiters(delimiters)
    delimiters ||= '[]'
    delimiters = case delimiters.size
    when 0
      ['','']
    when 1
      delimiters*2
    else
      delimiters[0,2].split(//)
    end
    delimiters
  end
  private :parse_character_set_delimiters
  
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
  
end

require 'lib/examination'
require 'lib/bun/expression'
