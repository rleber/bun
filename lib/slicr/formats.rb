#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

module Slicr
  module Formatted
    def self.included(base)
      base.extend(ClassMethods)
      base.send :alias_method, :inspect_before_formatting, :inspect
      base.send(:define_method, :inspect) do
        format(:inspect)
      end
      base.send :alias_method ,:to_s_before_formatting, :to_s
      base.send(:define_method, :to_s) do
        format(:default)
      end
    end
    
    def formats
      self.class.formats
    end
    
    def format_names
      self.class.format_names
    end

    def format(format_defn=nil, inspecting=false)
      case format_defn
      when nil
        return format(:default, inspecting)
      when :inspect
        format = formats[format_defn]
        return format.nil? ? inspect_before_formatting : format(format, true)
      when Symbol
        format = formats[format_defn]
        if format.nil?
          return inspect_before_formatting if inspecting # We're in a recursive loop
          return format(:inspect, true)
        else
          return format(format, inspecting)
        end
      when Format
        return format(format_defn.definition, inspecting) if format_defn.definition.is_a?(Symbol)
        v = format_defn.string? ? self.string : ( self.respond_to?(:asc) ? self.asc : self.value )
        if format_defn.inspect?
          if v.respond_to?(:inspect_before_formatting)
            v = v.inspect_before_formatting 
          else
            v = v.inspect
          end
        end
        format_defn = format_defn.definition
      when String
        v = format_defn=~/%[- *#\d]*s/ ? self.string : self.value
      else
        raise ArgumentError, "Unknown format type #{format_defn.inspect}"
      end
      format_defn % [v]
    end
    
    module ClassMethods
      # TODO Allow for unpadded formatting, and types which are unpadded by default
      # TODO More extensive DSL for defining formats, e.g. alignment, padding, width
      def global_format(name, format)
        Format.define(name, format)
      end
        
      def global_formats(formats)
        Format.define_from_hash(formats)
      end
      
      def default_format
        if @default_format
          @default_format
        else
          sign = sign_type rescue :none
          is_string = string? rescue false
          (is_string ? :string_inspect : (sign == :none ? :octal : :decimal))
        end
      end
      
      def install_formats(options={})
        saved_formats = @formats || {}
        @formats = {}
        @format_names = []
        
        define_formats Format.formats_for_class(self)
        define_formats saved_formats

        format_overrides = options[:formats] || {}
        define_formats format_overrides
        
        if options[:default] || !@formats[:default]
          define_format :default, (options[:default_format] || default_format)
        end
        
        if !@formats[:inspect]
          define_format :inspect, @formats[:default]
        end
        
        (@formats.keys - [:default, :inspect]).each do |format_name|
          define_format_method format_name
        end
      end
      
      def define_formats(format_hash)
        format_hash.each {|name, format| define_format(name, format) }
      end
      
      def define_format(name, format)
        case format
        when nil
          return define_format(name, default_format)
        when Format
          if format.name != name
            format = format.dup
            format.name = name
          end
        else
          format = Format.new(name, format)
        end
        adjusted_format = format.adjusted_format(self)
        raise RuntimeError, "Format #{format.name.inspect} is not supported for #{self.name}." unless adjusted_format
        @formats ||= {}
        @format_names ||= []
        @formats[adjusted_format.name] = adjusted_format
        @format_names << adjusted_format.name unless @format_names.include?(adjusted_format.name)
      end
        
      def define_format_method(format_name)
        def_method format_name do ||
          format(format_name)
        end
      end
      
      def formats
        install_formats unless @formats
        @formats
      end
      
      def format_samples=(samples)
        @format_samples = samples
      end
      
      def format_samples
        @format_samples
      end
      
      def format_names
        install_formats unless @format_names
        @format_names
      end

      def format_name(n)
        @format_names[n]
      end
      
      def format_definitions
        @format_names.inject({}) do |hsh, key|
          hsh[key] = @formats[key].definition
          hsh
        end
      end
      
      def format_definition(name)
        defn = @formats[name]
        return nil unless defn
        defn.definition
      end
      
    end
  end
  
  class Format

    FORMAT_WIDTH_WILDCARD = '*'
    
    attr_reader :name
    attr_accessor :definition
    attr_reader :name_string
    
    @@formats = {}
    
    class << self
      def ones_mask(n)
        2**n-1
      end
      
      def format_samples(size)
        [
          ones_mask(size),    # All '1' bits
          ones_mask(size-1),  # All '1' bits, except for possible leading sign
          1<<(size-1),        # '1' bit in possible leading sign, otherwise zero
          0,                  # All '0' bits
        ]
      end

      def define_from_hash(formats)
        table = {}
        formats.each do |name, format|
          table[name] = define(name, format)
        end
        table
      end
      
      def define(name, format)
        name = name.to_sym
        format = new(name, format) unless format.is_a?(Symbol)
        @@formats[name] = format
      end

      def formats_for_class(klass)
        table = {}
        @@formats.each do |name, format|
          name_string = name.to_s
          format_obj = format
          format_obj = @@formats[format] if format.is_a?(Symbol)
          next unless format_obj
          next unless format_obj.suited_for(klass)
          table[name] = format
        end
        table
      end
    end

    def initialize(name, definition)
      self.name = name
      set_format_types
      @definition = definition
    end
    
    def name=(name)
      @name = name.to_sym
      @name_string = name.to_s
    end
      
    def set_format_types
      @string_format = name_string =~ /string/
      @inspect = name_string =~ /inspect/
    end

    define :binary,         "%0#*b"
    define :octal,          "%0#*o"
    define :decimal,        "%*d"
    define :hex,            "%0#*x"
    define :string,         "%-*s"
    define :string_inspect, "%-*s"
    
    def string?
      @string_format
    end
    
    def inspect?
      @inspect
    end

    def suited_for(klass)
      klass_is_string = klass.string? rescue false
      klass_is_string || !string?
    end
    
    def adjusted_format(klass)
      definition = self.definition
      return self if definition.is_a?(Symbol)
      # TODO this doesn't word for MultiWords; not sure why
      width = klass.width rescue nil
      width ||= klass.word_size rescue nil
      width ||= 0
      format_samples = klass.format_samples || self.class.format_samples(width)
      nbits = klass.significant_bits rescue width
      if !string? && nbits == 1 # Special case for single bits (binary, octal, decimal, and hex representations are all the same)
        definition = definition.gsub(/%.*(?:#{Regexp.escape(FORMAT_WIDTH_WILDCARD)})?.*?([a-z])/, '%\1')
      end
      sample_definition = definition.gsub(FORMAT_WIDTH_WILDCARD, '')
      # TODO This is essentially an implementation of <data_class>#format: refactor it
      if string? && klass.string?
        format_samples = format_samples.map do |v|
          v.chr rescue ''
        end 
      end
      sample_texts = format_samples.map{|v| sample_definition % [v] }
      width = sample_texts.map{|t| t.size}.max
      adjusted_format = self.dup
      adjusted_format.definition = definition.gsub(FORMAT_WIDTH_WILDCARD, width.to_s)
      adjusted_format
    end

  end
end