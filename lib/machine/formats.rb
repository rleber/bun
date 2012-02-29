module Machine
  module Formatted
    def self.included(base)
      base.extend(ClassMethods)
    end
    
    def formats
      self.class.formats
    end
    
    module ClassMethods
      def define_formats(formats)
        Format.define(formats)
      end
      
      def default_format
        return @default_format if @default_format
        sign = sign_type rescue :none
        is_string = string? rescue false
        (is_string ? :string_inspect : (sign == :none ? :octal : :decimal))
      end
      
      def add_formats(new_formats=nil, options={})
        format_overrides = options[:format_overrides] || {}
        default_format = options[:default_format] || :octal
        new_formats ||= Format.formats_for_class(self)
        new_formats.each do |name, format|
          add_format(format, :format_overrides=>format_overrides)
        end
      
        default = formats[default_format]
        inspect_format = Format.new(:inspect, default.definition)
        add_format inspect_format
        # add_format Format.new(:inspect, default.definition)
        add_format Format.new(:default, default.definition), :no_method=>true
        
        # TODO: Allow for unpadded formatting, and types which are unpadded by default
        # TODO: Base inspect formatting on Class statically-defined inspect method?
        def_method :format do |*args|
          format_defn = args[0] || :default
          format = formats[format_defn] if format_defn.is_a?(Symbol)
          if format
            format_definition = format.definition
            v = format.string? ? self.string : self.value
            v = v.inspect if format.inspect?
          else
            format_definition = format_defn || word_default_format # TODO '%p' would be better, but would cause endless recursion currently
            v = self.value
          end
          format_definition % [v]
        end
      end

      def add_format(format, options={})
        format_overrides = options[:format_overrides] || {}
        adjusted_format = format.adjusted_format(self, format_overrides)
        raise RuntimeError, "Format #{format.name.inspect} is not supported for #{self.name}." unless adjusted_format
        @formats ||= {}
        @format_types ||= []
        @formats[adjusted_format.name] = adjusted_format
        unless @format_types.include?(adjusted_format.name)
          @format_types << adjusted_format.name
          unless options[:no_method]
            def_method adjusted_format.name do ||
              format(adjusted_format.name)
            end
          end
        end
      end
      
      def formats
        @formats
      end
      
      def format_samples=(samples)
        @format_samples = samples
      end
      
      def format_samples
        @format_samples
      end
      
      def format_types
        @format_types
      end

      def format_type(n)
        @format_types[n]
      end
      
      def format_definitions
        @format_types.inject({}) do |hsh, key|
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
    attr_reader :definition
    attr_reader :name_string
    
    @@formats = {}
    
    class << self
      def format_samples(size)
        [
          Machine::Word.ones_mask(size),   # All '1' bits
          Machine::Word.ones_mask(size-1), # All '1' bits, except for possible leading sign
          1<<(size-1),                    # '1' bit in possible leading sign, otherwise zero
          0,                              # All '0' bits
        ]
      end

      def define(formats)
        table = {}
        formats.each do |name, format_string|
          name = name.to_sym
          table[name] = @@formats[name] = new(name, format_string)
        end
        table
      end

      def formats_for_class(klass)
        table = {}
        @@formats.each do |name, format|
          name_string = name.to_s
          next unless format.suited_for(klass)
          table[name] = format
        end
        table
      end
    end

    def initialize(name, definition)
      @name = name.to_sym
      @definition = definition
      @name_string = name.to_s
      @string_format = name_string =~ /string/
      @inspect = name_string =~ /inspect/
    end
    
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
    
    def adjusted_format(klass, format_overrides={})
      definition = self.definition
      definition = format_overrides[name] if format_overrides[name]
      # TODO this doesn't word for MultiWords; not sure why
      size = klass.size rescue klass.word_size
      size ||= 0
      format_samples = klass.format_samples || self.class.format_samples(size)
      nbits = klass.significant_bits rescue size
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
      self.class.new(name, definition.gsub(FORMAT_WIDTH_WILDCARD, width.to_s))
    end

  end
end