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
  
  def examination(analysis)
    examiner = String::Examination.create(analysis)
    examiner.string = self
    examiner
  end
  
  
  
  def titleize
    split(/(\W)/).map(&:capitalize).join
  end
  
  def character_set(options={})
    chars = self.dup.force_encoding('ascii-8bit').split(//).sort.uniq
    runs = [""]
    last_asc = -999
    last_runnable = false
    chars.each do |ch|
      ch_asc = ch[0].ord
      ch_runnable = ch=~/[a-z0-9]/i || ch.inspect=~/"\\x/
      if !ch_runnable ||
         !last_runnable ||
         ch =~ /[aA0\x00]/ ||  # Don't allow a-z to run into A-Z, etc.
         ch_asc != last_asc + 1
        runs << ((ch=='-') ? '\\-' : ch) # Always escape '-' to avoid ambiguity
      else # Add to a run
        if runs.last =~ /^.-.$/m # Add to an existing run
          runs.last[-1,1] = ch
        elsif runs.last.size < 3 && runs.last.inspect.size < 10 # Not big enough for a run yet
                                                                # Last.inspect etc. for "\x00-..."
          runs[-1] += ch
        else # Create a new run
          runs[-1] = "#{runs.last[0,1]}-#{ch}"
        end
      end
      last_asc = ch_asc
      last_runnable = ch_runnable
    end
    runs_string = runs.join
    runs_string = '-' if runs_string == "\\-"
    runs_output = runs_string.inspect
    if runs_string.size > 1 || !options[:single_as_string]
      runs_output = '[' + runs_output[1..-2].gsub('/','\/').gsub('\\\\-', '\\-') + ']'
    end
    runs_output
  end
  
  def digest
    Digest::MD5.hexdigest(self).inspect[1..-2] # Inspect prevents YAML from treating this as binary
  end
  
  def freeze_for_thor
    self.gsub("\n","\x5").gsub(' ',"\177")
  end
  
end

require 'lib/string_examination'
