module Machine
  class Format

    FORMAT_WIDTH_WILDCARD = '<width>'
    
    attr_reader :name
    attr_reader :definition

    def initialize(name, definition)
      @name = name.to_sym
      @definition = definition.gsub(/\*/, FORMAT_WIDTH_WILDCARD)  # TODO Is this necessary?
      name_string = name.to_s
      @string_name = name_string =~ /string/
      @inspect = name_string =~ /inspect/
    end
    
    def string?
      @string_format
    end
    
    def inspect?
      @inspect
    end

    def suited_for(slice_class)
      slice_class.string? || !string?
    end
    
    def adjusted_definition(slice_class)
      definition = self.definition
      definition = slice_class.definition.formats[name] if slice_class.definition.formats[name]
      sample_values = slice_class.sample_values
      if !string? && slice_class.significant_bits == 1 # Special case for single bits (binary, octal, decimal, and hex representations are all the same)
        definition = definition.gsub(/%.*(?:#{FORMAT_WIDTH_WILDCARD})?.*?([a-z])/, '%\1')
      end
      sample_definition = definition.gsub(FORMAT_WIDTH_WILDCARD, '')
      sample_values = sample_values.map{|v| v.chr } if string? && slice_class.string?
      sample_texts = sample_values.map{|v| sample_definition % [v] }
      width = sample_texts.map{|t| t.size}.max
      self.class.new(name, definition.gsub(FORMAT_WIDTH_WILDCARD, width.to_s))
    end

    @@formats = {}
  
    def self.define(formats)
      table = {}
      formats.each do |name, format_string|
        name = name.to_sym
        table[name] = @@formats[name] = new(name, format_string)
      end
      table
    end
    
    def self.formats_for_slice(slice_class)
      table = {}
      @@formats.each do |name, format|
        name_string = name.to_s
        next unless format.suited_for(slice_class)
        table[name] = format
      end
      table
    end
  end
end