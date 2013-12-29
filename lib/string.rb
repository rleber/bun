#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

class String
  class InvalidCheck < ArgumentError; end

  def escaped
    self.inspect[1..-2]
  end
  
  class Analysis; end # Defined elsewhere
  
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
    define_method("#{key}_regexp}") { const_get("#{key.upcase}_REGEXP") }
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

    # TODO Refactor this, using a String::Check class?
    CHECK_TESTS = {
      clean: {
        options: [:clean, :dirty],
        description: "File contains special characters",
        test: lambda {|text| text.clean? ? :clean : :dirty }
      },
      tabbed: {
        options: [:tabs, :no_tabs],
        description: "File contains tabs",
        test: lambda {|text| text.tabbed? ? :tabs : :no_tabs }
      },
      overstruck: {
        options: [:tabs, :no_tabs],
        description: "File contains backspaces",
        test: lambda {|text| text.overstruck? ? :overstruck : :not_overstruck }
      },
      english: {
        description: "Proportion of english vs. non-english characters",
        test: lambda {|text| text.english_proportion },
        format: lambda {|res| '%0.2f%' % (res*100.0) }
      },
      
    }

    def check_tests
      CHECK_TESTS
    end
    
  end

  
  def english_proportion
    counts = english_counts
    counts[:english][:count]*1.0 / (counts[:english][:count] + counts[:non_english][:count])
  end
  
  def pattern_counts(*character_sets)
    counter = String::Analysis::Base.new(self, character_sets)
    counter.pattern_counts
  end
  
  def character_class_counts(*character_sets)
    counter = String::Analysis::Base.new(self, character_sets)
    counter.character_counts
  end
  
  def analyze(analysis)
    analyzer = String::Analysis.create(analysis)
    analyzer.string = self
    analyzer
  end

  def clean?
    self.force_encoding('ascii-8bit') !~ String.invalid_character_regexp
  end
  
  def tabbed?(text)
    self.force_encoding('ascii-8bit') !~ String.tab_regexp
  end
  
  def overstruck?(text)
    self.force_encoding('ascii-8bit') !~ String.backspace_regexp
  end
  
  def check(test)
    spec = self.class.check_tests[test.to_sym]
    raise InvalidCheck, "!Invalid test: #{test.inspect}" unless spec
    test_result = spec[:test].call(self)
    if spec[:options]
      ix = spec[:options].index(test_result) || spec[:options].size
    else
      ix = nil
    end
    test_result = spec[:format].call(test_result) if spec[:format]
    {code: ix, description: test_result}
  end
  
  def titleize
    split(/(\W)/).map(&:capitalize).join
  end
  
  def character_set
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
        runs << ch
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
    '[' + runs.join.inspect[1..-2].gsub('/','\/') + ']'
  end
end

require 'lib/string_analysis'
require 'lib/string_check'
