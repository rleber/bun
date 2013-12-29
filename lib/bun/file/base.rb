#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

require 'lib/bun/file/descriptor'
require 'yaml'
require 'date'

# TODO Move to a separate file
class String
  class InvalidCheck < ArgumentError; end

  def escaped
    self.inspect[1..-2]
  end
  
  class << self
  
    VALID_CONTROL_CHARACTER_HASH = {
      new_line:        "\n", 
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

    def valid_control_character_array
      VALID_CONTROL_CHARACTER_ARRAY
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
    
    # TODO Refactor this, using a String::Analysis class?
    ANALYSES = {
      control_characters: {
        description: "Count control characters",
        fields: %w{Character Count},
        test: lambda {|text| text.control_character_counts },
        format: lambda do |analysis|
          table = [%w{Character Count}]
          analysis.to_a.sort_by {|row| -row.last} \
          .each do |character, count|
            table << [character.inspect, count.to_s]
          end
          table.justify_rows(right_justify: [1])
        end
      },
      characters: {
        description: "Count all characters",
        fields: %w{Character Count},
        test: lambda {|text| text.character_counts },
        format: lambda do |analysis|
          table = [%w{Character Count}]
          analysis.to_a.sort_by {|row| -row.last} \
          .each do |character, count|
            table << [character.inspect, count.to_s]
          end
          table.justify_rows(right_justify: [1])
        end
      },
      english: {
        description: "Count english vs. non-english characters",
        fields: %w{Category Count},
        test: lambda {|text| text.english_counts },
        format: lambda do |analysis|
          table = [%w{Category Count}]
          analysis.to_a.sort_by {|row| -row.last} \
          .each do |category, count|
            table << [category.inspect, count.to_s]
          end
          table.justify_rows(right_justify: [1])
        end
      },
    }

    def analyses
      ANALYSES
    end
  end

  def control_character_counts
    pats = self.class.valid_control_character_array + [self.class.invalid_character_regexp]
    character_counts(pats)
  end
  
  def english_counts
    english = 'a-zA-Z0-9\.,()\-'
    pats = [/[#{english}]/,/[^#{english}]/]
    counts = pattern_counts(pats)
    counts += [{count: 0}]*2
    { english: counts[0][:count], non_english: counts[1][:count] }
  end
  
  def english_proportion
    counts = english_counts
    counts[:english]*1.0 / (counts[:english] + counts[:non_english])
  end
  
  def pattern_counts(*character_sets)
    character_sets = [/./] if character_sets.size == 0 # Match anything
    encoded = self.force_encoding('ascii-8bit')
    counts = []
    [character_sets].flatten.each.with_index do |pat, i|
      encoded.scan(pat) do |ch|
        counts[i] ||= {index:i, character:ch, count: 0}
        counts[i][:count] += 1
      end
    end
    counts
  end
  
  def character_counts(*character_sets)
    counts = pattern_counts(*character_sets)
    counts.inject({}) {|hsh, entry| hsh[entry[:character]] = entry[:count]; hsh }
  end
  
  def analyze(analysis)
    spec = self.class.analyses[analysis.to_sym]
    raise InvalidCheck, "!Invalid analysis: #{analysis.inspect}" unless spec
    spec[:test].call(self)
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
end

module Bun

  class File < ::File

    class << self
      
      def preread(path)
        return $stdin_tempfile if $stdin_tempfile
        if path == '-'
          tempfile = Tempfile.new('stdin')
          tempfile.write($stdin.read)
          tempfile.close
          $stdin_tempfile = tempfile.path
        else
          path
        end
      end
      
      def read(*args)
        path = preread(args.first)
        args[0] = path
        ::File.read(*args)
      end

      def relative_path(*f)
        options = {}
        if f.last.is_a?(Hash)
          options = f.pop
        end
        relative_to = options[:relative_to] || ENV['HOME']
        File.expand_path(File.join(*f), relative_to).sub(/^#{Regexp.escape(relative_to)}\//,'')
      end

      def control_character_counts(path)
        Bun.readfile(path).control_character_counts
      end
      
      def check(path, test)
        read(path).check(test)
      end
      
      def analyze(path, analysis)
        read(path).analyze(analysis)
      end
  
      def descriptor(options={})
        Header.new(options).descriptor
      end
      
      def packed?(path)
        prefix = File.read(path, 3)
        prefix != '---' # YAML prefix; one of the unpacked formats
      end
      
      def open(path, options={}, &blk)
        if packed?(path)
          File::Packed.open(path, options, &blk)
        else
          File::Unpacked.open(path, options, &blk)
        end
      end
      
      def file_type(path)
        return :packed if packed?(path)
        begin
          f = File::Unpacked.open(path)
          f.file_type
        rescue
          :unknown
        end
      end
      
      def descriptor(path, options={})
        open(path) {|f| f.descriptor }
      rescue Bun::File::UnknownFileType =>e 
        nil
      rescue Errno::ENOENT => e
        return nil if options[:allow]
        stop "!File #{path} does not exist" if options[:graceful]
        raise
      end
      
      # Convert from packed format to unpacked (i.e. YAML)
      def unpack(path, to, options={})
        return unless packed?(path)
        open(path) do |f|
          cvt = f.unpack
          cvt.descriptor.tape = options[:tape] if options[:tape]
          cvt.descriptor.merge!(:unpack_time=>Time.now, :unpacked_by=>Bun.expanded_version)
          cvt.write(to)
        end
      end
      
      def expand_path(path, relative_to=nil)
        path == '-' ? path : super(path, relative_to)
      end
    end
    attr_reader :archive
    attr_reader :tape_path

    attr_accessor :descriptor
    attr_accessor :errors
    attr_accessor :decoded
    attr_accessor :original_tape
    attr_accessor :original_tape_path

    def initialize(options={}, &blk)
      @tape = options[:tape]
      @tape_path = options[:tape_path]
      @size = options[:size]
      @archive = options[:archive]
      clear_errors
      yield(self) if block_given?
    end

    # private_class_method :new
  
    def clear_errors
      @errors = []
    end

    def error(err)
      @errors << err
    end
  
    def open_time
      return nil unless tape_path && File.exists?(tape_path)
      File.atime(tape_path)
    end
  
    def close
      # update_index
    end
  
    def read
      self.class.read(tape_path)
    end
  
    def update_index
      return unless @archive
      @archive.update_index(:file=>self)
    end

    def tape
      @tape ||= File.basename(tape_path)
    end
  
    def path
      descriptor.path
    end
  
    def updated
      descriptor.updated
    end
  
    def copy_descriptor(to, new_settings={})
      descriptor.copy(to, new_settings)
    end
  end
end