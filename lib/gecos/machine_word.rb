# Class for defining generic machine words

class Object
  def singleton_class
    class << self; self; end
  end
end

class Class
  def define_class_method(name, &block)
    warn "Dynamically defining class method #{self.class}.#{name}" if $trace
    singleton_class.instance_eval do
      define_method(name) do
        yield
      end
    end
  end
  
  def def_method(name, &blk)
    warn "Dynamically defining instance method #{self.name}##{name}" if $trace
    define_method(name, &blk)
  end

  def define_parameter(name, value=nil, &blk)
    value = yield if block_given?
    const_set name.to_s.upcase.sub(/[?!]?$/,''), value
    def_method(name.to_s.downcase) { value }
    singleton_class.instance_eval do
      def_method(name.to_s.downcase) { value }
    end
    value
  end
  
  def define_collection(name, value=nil, &blk)
    name = name.to_s.downcase
    value = define_parameter(name+"s", value, &blk)
    def_method name do |n|
      self.send(name+"s")[n]
    end
    singleton_class.instance_eval do
      def_method(name.to_s.downcase) {|n| self.send(name+"s")[n] }
    end
  end
  
  # TODO Remove this
  def define_class(name)
  end
end

class GenericNumeric

  attr_reader :value
  
  def initialize(value)
    raise TypeError, "Value for #{self.class} not numeric (#{value.inspect})" unless value.is_a?(Numeric)
    @value = value
  end

  def to_int
    @value
  end
  
  def method_missing(name, *args, &blk)
    ret = @value.send(name, *args, &blk)
    ret.is_a?(Numeric) ? self.class.new(ret) : ret
  end
end

module Machine
  
  module Slice
    class Base < GenericNumeric
      def self.clip(value)
        self.class.all_ones & value
      end
  
      def initialize(options={})
        raise RuntimeError, "#{self.class} does not understand signed values" if options[:signed_value]
        raise RuntimeError, "No value provided for #{self.class}" unless val=options[:unsigned_value]
        raise RuntimeError, "Cannot initialize #{self.class} with a negative value" unless val >= 0
        super(val)
      end
  
      def unsigned_value
        self.value
      end
    end
    

    class Numeric < Base; end
    
    class Unsigned < Numeric; end

    module Signed
      class TwosComplement < Numeric
        
        class << self 
          def complement(bits)
            raise RuntimeError, "Can't take complement of a negative number (#{bits})" unless bits >= 0
            unprotected_complement(bits)
          end
          
          def sign_bit
            0
          end
          
          def sign_mask
            single_bit_masks[sign_bit]
          end

          def unprotected_complement(value)
            clip( ~value + 1)
          end
          private :unprotected_complement
        end
    
        def initialize(options={})
          if val=options[:signed_value]
            super(:unsigned_value=>complement(val))
          else
            super
          end
        end
    
        def sign
          @unsigned_value & self.class.sign_mask
        end

        def complement
          self.class.complement(@unsigned_value)
        end
      
        def signed_value
          sign==0 ? @unsigned_value : negative_value
        end
      
        def negative_value
          -absolute_value
        end
      
        def absolute_value
          sign==0 ? @unsigned_value : complement
        end
      end
      
      class OnesComplement < TwosComplement
        class << self 
          def unprotected_complement(value)
            clip( ~value)
          end
          private :unprotected_complement
        end
      end
    end
  
    class String < Base
      def to_str
        @value.chr
      end
    
      def +(other)
        @value.chr + other
      end
    
      def add(other)
        @value + other
      end
    end
  
    class Array < ::Array
      def merge
        self.map{|e| e.string}.join
      end
    
      def values
        self.map{|e| e.values}
      end
    end
  end

  class Word < GenericNumeric
  
    FORMAT_WIDTH_WILDCARD = /<width>/
    define_parameter :formats, {
      :binary=>  "%0#<width>b", 
      :octal=>   "%0#<width>o", 
      :decimal=> "%<width>d",
      :hex=>     "%0#<width>x",
      :string=>  "%-<width>s"
    }
  
    def self.define_size(word_size)
      ones = eval('0b' + ('1'*word_size))
      # Has an extra entry, for consistency with other collections
      single_bit_masks    = (0..word_size).map {|n| 1<<n }.reverse
      # Note that the following collections all have one extra entry
      preceding_bit_masks = (0..word_size).map {|n| ones>>n }
      following_bit_masks = (0..word_size).map {|n| ones & (ones << n) }
      lower_bit_masks     = preceding_bit_masks.reverse
      n_bit_masks         = lower_bit_masks
      upper_bit_masks     = following_bit_masks.reverse

      define_parameter :size, word_size
      define_parameter :all_ones, ones
    
      define_collection :single_bit_mask,    single_bit_masks
      define_collection :preceding_bit_mask, preceding_bit_masks
      define_collection :following_bit_mask, following_bit_masks
      define_collection :n_bit_mask,         n_bit_masks
      define_collection :lower_bit_mask,     lower_bit_masks
      define_collection :upper_bit_mask,     upper_bit_masks
    
      define_slice :word, :size=>word_size
    end
  
    def self.bit_mask(from, to)
      preceding_bit_masks[from] & upper_bit_masks[to+1]
    end
  
    def self.exclusive_bit_mask(from, to)
      all_ones ^ bit_mask(from, to)
    end
  
    def self.slice_start_bit(n, size, offset=0)
      n*size + offset
    end
  
    def self.slice_end_bit(n, size, offset=0)
      slice_start_bit(n+1, size, offset) - 1
    end
  
    def self.slice_mask(n, size, offset)
      bit_mask(slice_start_bit(n, size, offset), slice_end_bit(n, size, offset))
    end
  
    def self.slices_per_word(slice_size, offset)
      (size - offset).div(slice_size)
    end
  
    VALID_SIGNS = [:none, :ones_complement, :twos_complement]
    # TODO Define :sign option: :none, :ones_complement, :twos_complement
    # TODO Define fields (i.e. non-repeating parts of a word)
    # TODO Define structures (i.e. a sequence of fields -- possibly multiword?)
    # TODO Define bit and byte order (i.e. LR, RL)
    # TODO Define signs other than at the beginning of a slice
    def self.define_slice(slice_name, options={})
      slice_name = slice_name.to_s.downcase
      slice_size = options[:size]
      slice_offset = options[:offset] || 0
      bits = options[:bits] || slice_size
      clipping_mask = options[:mask] || n_bit_masks[bits]
      default_format = options[:format] || :octal
      is_string = !!options[:string]
      sign = options[:sign] || :none
    
      class_name = slice_name.gsub(/(^|_)(.)/) {|match| $2.upcase}
      if is_string
        parent = Slice::String
      else
        parent = case sign
        when :none then Slice::Unsigned
        when :ones_complement then Slice::Signed::OnesComplement
        when :twos_complement then Slice::Signed::TwosComplement
        else  
          raise RuntimeError, "Bad value for :sign (#{sign.inspect}). Should be one of #{VALID_SIGNS.inspect}"
        end
      end
      slice_class = Class.new(parent)
      const_set(class_name, slice_class)
      add_slice(slice_name, options.merge(:class=>slice_class))

      # slice_class.send(:def_method, :initialize) do |value|
      #   @value = value
      # end
      # slice_class.send(:attr_accessor, :value)
      # slice_class.send(:attr_reader, :unsigned_value)
    
      per_word = slices_per_word(slice_size, slice_offset)
      start_bits = (0...per_word).map{|n| slice_start_bit(n, slice_size, slice_offset) }
      end_bits = (0...per_word).map{|n| slice_end_bit(n, slice_size, slice_offset) }
      shifts = end_bits.map{|end_bit| size - end_bit - 1 }
      
      masks = (0...per_word).map do |n|
        mask = slice_mask(n, slice_size, slice_offset)
        clip_to = (clipping_mask << (size - end_bits[n] - 1))
        res = mask & clip_to
      end
    
      define_parameter "#{slice_name}_slice_size",             slice_size
      define_parameter "#{slice_name}_slice_offset",           slice_offset
      define_parameter "#{slice_name}_slices_per_word",        per_word
      define_parameter "#{slice_name}_slice_significant_bits", bits
      define_parameter "#{slice_name}_slice_string?",          !!is_string
      define_parameter "#{slice_name}_slice_clipping_mask",    clipping_mask
    
      slice_class.define_parameter  "size",              slice_size
      slice_class.define_parameter  "offset",            slice_offset
      slice_class.define_parameter  "per_word",          per_word
      slice_class.define_parameter  "significant_bits",  bits
      slice_class.define_parameter  "string?",           is_string
      slice_class.define_parameter  "clipping_mask",     clipping_mask
    
      define_collection "#{slice_name}_slice_end_bit",   end_bits
      define_collection "#{slice_name}_slice_start_bit", start_bits
      define_collection "#{slice_name}_slice_shift",     shifts
      define_collection "#{slice_name}_slice_mask",      masks

      slice_class.define_collection "end_bit",     end_bits
      slice_class.define_collection "start_bit",   start_bits
      slice_class.define_collection "shift",       shifts
      slice_class.define_collection "mask",        masks
    
      slice_formats = {}
      formats.each do |format, definition|
        next if format==:string && !is_string
        sample_values = [n_bit_masks[bits], n_bit_masks[bits-1]||0, 0]
        if format!=:string && bits == 1 # Special case for single bits (binary, octal, decimal, and hex representations are all the same)
          definition = definition.gsub(/%.*(?:#{FORMAT_WIDTH_WILDCARD})?.*?([a-z])/, '%\1')
        end
        sample_definition = definition.gsub(FORMAT_WIDTH_WILDCARD, '')
        sample_values = sample_values.map{|v| v.chr } if format == :string && is_string
        sample_texts = sample_values.map{|v| sample_definition % [v] }
        width = sample_texts.map{|t| t.size}.max
        definition = definition.gsub(FORMAT_WIDTH_WILDCARD, width.to_s)
        slice_formats[format] = {:name=>format, :string=>definition, :max_width=>width}
        slice_class.define_parameter "#{format}_format_string", definition[:string]
        slice_class.send(:def_method, format.to_s) do
          definition % [self.value]
        end
      end
      slice_formats[:default] = slice_formats[default_format]
    
      if is_string
        slice_formats[:inspect] = {
          :name=>:inspect, :string=>slice_formats[:octal][:string] + '::' + slice_formats[:string][:string], 
          :max_width=>slice_formats[:octal][:max_width] + 2 + slice_formats[:string][:max_width]
        }
      else
        slice_formats[:inspect] = slice_formats[:default]
      end
      format_strings = slice_formats.inject({}){|hsh, kv| key, value = kv; hsh[key] = value[:string]; hsh}
      format_widths  = slice_formats.inject({}){|hsh, kv| key, value = kv; hsh[key] = value[:max_width]; hsh}
      slice_class.define_collection "format_definition", slice_formats
      slice_class.define_collection "format_string", format_strings
      slice_class.define_collection "format_width",  format_widths
      slice_class.define_collection "format_type",   slice_formats.keys.sort_by{|f| f.to_s}
    
      slice_class.send(:def_method, :format) do |*args|
        format = args[0] || :default
        format_string = format
        format_string = slice_formats[format][:string] if format.is_a?(Symbol)
        v = self.value
        v = v.chr if format==:string && is_string
        values = [v] * (format_string.gsub(/[^%]/,'').size)
        format_string % values
      end
    
      slice_class.send(:def_method, :inspect) do
        format(:inspect)
      end
    
      unshifted_method_name = "unshifted_#{slice_name}"
      def_method unshifted_method_name do |n|
        value & masks[n]
      end
    
      def_method slice_name do |n|
        slice_class.new(:unsigned_value=>self.send(unshifted_method_name, n) >> shifts[n])
      end
      def_method "#{slice_name}s" do
        ary = Slice::Array.new
        (0...per_word).each {|n| ary << self.send(slice_name, n) }
        ary
      end

      if is_string
        slice_class.send(:def_method, :string) do
          self.chr
        end
        slice_class.send(:def_method, :string_inspect) do
          self.string.inspect
        end
        def_method "#{slice_name}_string" do |n|
          (0...per_word).map {|n| self.send(slice_name, n).string }
        end
      end
    end

    def clip(value)
      self.class.all_ones & value
    end
  
    def value=(value)
      @value = clip(value)
    end
  
    def unshifted_bits(from, to)
      value & bit_mask(from, to)
    end
  
    # TODO Allow negative indexing
    # TODO Consider a change which would permit indexing a la Array[]
    def bits(from, to)
      unshifted_bits(from, to) >> (size - to)
    end
  
    def bit(at)
      bits(at, at)
    end
  
    def slice(n, size, offset=0)
      start = (n-1)*size + offset
      bits(start, start+size-1)
    end
  
    def self.slices
      @slices ||=[]
    end
  
    def self.add_slice(name, definition)
      self.slices << definition.merge(:name=>name.to_sym)
    end
  
    def self.slice_names
      self.slices.map{|slice| slice[:name]}
    end
  end
end