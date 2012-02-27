# Class for defining generic machine words

# TODO Write API documentation
# TODO Significant refactoring to get rid of all the dynamic method definitions. For instance, could the 
# API change to word.byte.clipping_mask, and could the slice classes be largely statically defined, and then instantiated
# with a Slice::Definition object?

# TODO Either get rid of this trace stuff, or make it better
$trace = false

class Object
  def singleton_class
    class << self; self; end
  end
end

class Class
  def def_class_method(name, &blk)
    class_name = self.name
    raise NameError, "Attempt to redefine class method #{class_name}.#{name}" if self.methods.include?(name)
    puts "Dynamically defining class method #{class_name}.#{name}" if $trace
    expected_arguments = blk.arity < 0 ? nil : blk.arity
    singleton_class.instance_eval do
      define_method(name) do |*args|
        # puts "In #{class_name}.#{name}(#{args.map{|a| a.inspect}.join(',')})" if $trace
        # TODO Encapsulate parameter checking in a method, and use it everywhere: e.g. check_args(actual_arg_count, expected_arg_count)
        raise ArgumentError, "Incorrect number of arguments in #{class_name}.#{name}: #{args.size} for #{expected_arguments}" unless [nil, args.size].include?(expected_arguments)
        yield(*args)
      end
    end
  end
  
  def def_method(name, &blk)
    class_name = self.name
    raise NameError, "Attempt to redefine class method #{class_name}.#{name}" if self.instance_methods.include?(name)
    puts "Dynamically defining instance method #{class_name}##{name}" if $trace
    define_method(name, &blk)
    
    # TODO Figure out why the following doesn't work -- it seems to bind block to the context of the class, rather than the instance:
    # Based on http://blog.sidu.in/2007/11/ruby-blocks-gotchas.html, I think this MIGHT work in Ruby 1.9 with explicit block passing. I don't think it will work in Ruby 1.8
    # expected_arguments = blk.arity < 0 ? nil : blk.arity
    # define_method(name) do |*args|
    #   # puts "In #{class_name}.#{name}(#{args.map{|a| a.inspect}.join(',')})" if $trace
    #   raise ArgumentError, "Incorrect number of arguments in #{class_name}##{name}: #{args.size} for #{expected_arguments}" unless [nil, args.size].include?(expected_arguments)
    #   blk.call(*args)
    # end
  end

  def define_parameter(name, value=nil, &blk)
    class_name = self.name
    name = name.to_s.downcase
    value = yield if block_given?
    const_name = name.to_s.upcase.sub(/[?!]?$/,'')
    raise NameError, "Attempt to redefine parameter constant #{class_name}::#{const_name}" if self.const_defined?(const_name)
    const_set const_name, value
    # TODO Do argument count checking
    def_method(name) {|| value }
    def_class_method(name) {|| value }
    value
  end
  
  def define_collection(name, value=nil, &blk)
    name = name.to_s.downcase
    class_name = self.name
    value = define_parameter(name+"s", value, &blk)
    # TODO Do argument count checking
    puts "Dynamically defining instance method (collection) #{class_name}.#{name}" if $trace
    def_method name do |n|
      self.send(name+"s")[n]
    end
    def_class_method(name.to_s.downcase) {|n| self.send(name+"s")[n] }
  end
end

class String
  def pluralize
    self+'s'
  end
end

class GenericNumeric

  def initialize(value)
    @data = value
  end

  def to_int
    @data
  end
  
  def value
    @data
  end
  
  def internal_value
    @data
  end
  protected :internal_value
  
  def inspect
    "<#{self.class}: #{internal_value.inspect}>"
  end
  
  def method_missing(name, *args, &blk)
    ret = @data.send(name, *args, &blk)
    ret.is_a?(Numeric) ? self.class.new(ret) : ret
  end
end

module Machine
  
  module Slice
    class Base < GenericNumeric
      def self.clip(value)
        all_ones & value
      end
    end
    

    class Numeric < Slice::Base; end
    
    class Unsigned < Slice::Numeric
    end

    module Signed
      class TwosComplement < Slice::Numeric
        
        class << self 
          def sign_bit
            0
          end
          
          def sign_mask
            single_bit_mask(sign_bit)
          end
          
          def sign(val)
            val & sign_mask
          end

          def complement(value)
            clip( ~value + 1)
          end
        end
    
        attr_reader :ignore_sign
        
        def initialize(val, options={})
          super(val)
          @ignore_sign = options[:ignore_sign]
        end
        
        def value
          _signed
        end
    
        def sign
          (@ignore_sign ? 0 : self.class.sign(internal_value)) >> (size-self.class.sign_bit-1)
        end

        def complement
          self.class.new(_complement, :ignore_sign=>@ignore_sign)
        end

        def _complement
          self.class.complement(internal_value)
        end
        private :_complement
      
        def signed
          self.class.new(_signed, :ignore_sign=>false)
        end
    
        def _signed
          sign==0 ? _unsigned : -_abs
        end
        private :_signed
        
        def unsigned
          self.class.new(_unsigned, :ignore_sign=>true)
        end
        
        def _unsigned
          internal_value
        end
        private :_unsigned
      
        def abs
          self.class.new(_abs, :ignore_sign=>@ignore_sign)
        end
        
        def _abs
          sign==0 ? _unsigned : _complement
        end
        private :_abs
      end
      
      class OnesComplement < TwosComplement
        class << self 
          def complement(value)
            clip( ~value)
          end
        end
      end
    end
  
    class String < Base
      def to_str
        internal_value.chr
      end
    
      def +(other)
        internal_value.chr + other
      end
    
      def add(other)
        internal_value + other
      end
    end
  
    class Array < ::Array
      def string
        self.map{|e| e.string}.join
      end
      
      def values
        self.map{|e| e.values}
      end
    end
  end

  class Word < GenericNumeric
  
    FORMAT_WIDTH_WILDCARD = /<width>/
    # TODO Could this be improved using the '*' sprintf flag?
    # TODO Generalize the inspect thing
    define_parameter :formats, {
      :binary=>         "%0#<width>b", 
      :octal=>          "%0#<width>o", 
      :decimal=>        "%<width>d",
      :hex=>            "%0#<width>x",
      :string=>         "%-<width>s",
      :string_inspect=> "%-<width>s",
    }
  
    def self.define_size(word_size)
      ones = eval('0b' + ('1'*word_size))
      # Has an extra entry, for consistency with other collections
      single_bit_masks    = (0...word_size).map {|n| 1<<n }.reverse + [0]
      # Note that the following collections all have one extra entry
      strip_leading_bit_masks = (0..word_size).map {|n| ones>>n }
      strip_trailing_bit_masks = (0..word_size).map {|n| ones & (ones << n) }
      lower_bit_masks     = strip_leading_bit_masks.reverse
      n_bit_masks         = lower_bit_masks
      upper_bit_masks     = strip_trailing_bit_masks.reverse

      define_parameter :size, word_size
      define_parameter :all_ones, ones
    
      define_collection :single_bit_mask,    single_bit_masks
      define_collection :strip_leading_bit_mask, strip_leading_bit_masks
      define_collection :strip_trailing_bit_mask, strip_trailing_bit_masks
      define_collection :n_bit_mask,         n_bit_masks
      define_collection :lower_bit_mask,     lower_bit_masks
      define_collection :upper_bit_mask,     upper_bit_masks
    
      define_slice :word, :size=>word_size
    end
  
    def self.make_bit_mask(from, to)
      strip_leading_bit_masks[from] & upper_bit_masks[to+1]
    end
  
    def self.exclusive_bit_mask(from, to)
      all_ones ^ make_bit_mask(from, to)
    end
  
    def self.slice_start_bit(n, size, offset=0, gap=0)
      n*(size+gap) + offset
    end
  
    def self.slice_end_bit(n, size, offset=0, gap=0)
      slice_start_bit(n+1, size, offset, gap) - gap - 1
    end
  
    def self.slice_mask(n, size, offset=0, gap=0)
      make_bit_mask(slice_start_bit(n, size, offset, gap), slice_end_bit(n, size, offset, gap))
    end
  
    def self.slices_per_word(slice_size, offset=0, gap=0)
      available_bits = size - offset
      bits_per_slice = [slice_size+gap, available_bits].min
      available_bits.div(bits_per_slice)
    end
  
    VALID_SIGNS = [:none, :ones_complement, :twos_complement]
    # TODO Should word.byte mean word.byte(0) or word.byte(n)?
    # TODO Should be recursive -- i.e. Should be able to say word.half_word(0).byte(2)
    # TODO Define bit and byte order (i.e. LR, RL)
    # TODO Define signs other than at the beginning of a slice
    def self.define_slice(slice_name, options={})
      slice_name = slice_name.to_s.downcase
      slices_name = slice_name.pluralize
      slice_size = options[:size]
      slice_offset = options[:offset] || 0
      nbits = options[:bits] || slice_size
      clipping_mask = options[:mask] || n_bit_masks[nbits]
      is_string = !!options[:string]
      sign = options[:sign] || :none
      default_format = options[:default_format] || (is_string ? :string_inspect : (sign == :none ? :octal : :decimal))
      format_overrides = options[:format] || {}
      slice_gap = options[:gap] || 0
      per_word = options[:count]
    
      class_name = slice_name.gsub(/(^|_)(.)/) {|match| $2.upcase}
      if is_string
        parent = Slice::String
      else
        parent = case sign
        when :none then Slice::Unsigned
        when :ones_complement then Slice::Signed::OnesComplement
        when :twos_complement then Slice::Signed::TwosComplement
        else  
          raise ArgumentError, "Bad value for :sign (#{sign.inspect}). Should be one of #{VALID_SIGNS.inspect}"
        end
      end
      slice_class = Class.new(parent)
      const_set(class_name, slice_class)
      add_slice(slice_name, options.merge(:class=>slice_class))
      
      # TODO Refactor this stuff as a slice specification (size, gap, offset, etc.)
      per_word ||= slices_per_word(slice_size, slice_offset, slice_gap)
      start_bits = (0...per_word).map{|n| slice_start_bit(n, slice_size, slice_offset, slice_gap) }
      end_bits = (0...per_word).map{|n| slice_end_bit(n, slice_size, slice_offset, slice_gap) }
      shifts = end_bits.map{|end_bit| size - end_bit - 1 }
      
      masks = (0...per_word).map do |n|
        mask = slice_mask(n, slice_size, slice_offset, slice_gap)
        clip_to = (clipping_mask << (size - end_bits[n] - 1))
        res = mask & clip_to
      end
    
      define_parameter "#{slice_name}_size",              slice_size
      define_parameter "#{slice_name}_offset",            slice_offset
      define_parameter "#{slices_name}_per_word",         per_word
      define_parameter "#{slice_name}_significant_bits",  nbits
      define_parameter "#{slice_name}_string?",           is_string
      define_parameter "#{slice_name}_clipping_mask",     clipping_mask
    
      slice_class.define_parameter  "size",               slice_size
      slice_class.define_parameter  "offset",             slice_offset
      slice_class.define_parameter  "per_word",           per_word
      slice_class.define_parameter  "significant_bits",   nbits
      slice_class.define_parameter  "string?",            is_string
      slice_class.define_parameter  "clipping_mask",      clipping_mask

      # Again, all the bit masks have an extra entry
      slice_class.define_collection "single_bit_mask",    single_bit_masks[-(nbits+1)..-1]
      slice_class.define_collection "strip_leading_bit_mask", strip_leading_bit_masks[-(nbits+1)..-1]
      slice_class.define_collection "strip_trailing_bit_mask", strip_trailing_bit_masks[0..nbits]
      slice_class.define_collection "n_bit_mask",         n_bit_masks[0..nbits]
      slice_class.define_collection "lower_bit_mask",     lower_bit_masks[0..nbits]
      slice_class.define_collection "upper_bit_mask",     upper_bit_masks[-(nbits+1)..-1]
      slice_class.define_parameter  "all_ones",           all_ones & clipping_mask


      define_collection "#{slice_name}_end_bit",   end_bits
      define_collection "#{slice_name}_start_bit", start_bits
      define_collection "#{slice_name}_shift",     shifts
      define_collection "#{slice_name}_mask",      masks

      slice_class.define_collection "end_bit",     end_bits
      slice_class.define_collection "start_bit",   start_bits
      slice_class.define_collection "shift",       shifts
      slice_class.define_collection "mask",        masks
    
      # TODO This method is too long. Refactor it
      slice_formats = {}
      formats.each do |format, definition|
        format_string = format.to_s
        string_format = format_string =~ /string/
        next if string_format && !is_string
        definition = format_overrides[format] if format_overrides[format]
        sample_values = [n_bit_masks[nbits], n_bit_masks[nbits-1]||0, n_bit_masks[0], 0]
        if !string_format && nbits == 1 # Special case for single bits (binary, octal, decimal, and hex representations are all the same)
          definition = definition.gsub(/%.*(?:#{FORMAT_WIDTH_WILDCARD})?.*?([a-z])/, '%\1')
        end
        sample_definition = definition.gsub(FORMAT_WIDTH_WILDCARD, '')
        sample_values = sample_values.map{|v| v.chr } if string_format && is_string
        sample_texts = sample_values.map{|v| sample_definition % [v] }
        width = sample_texts.map{|t| t.size}.max
        definition = definition.gsub(FORMAT_WIDTH_WILDCARD, width.to_s)
        format_spec = {:name=>format, :definition=>definition, :max_width=>width}
        format_spec[:inspect] = true if format_string =~ /inspect/
        format_spec[:string_format] = string_format
        slice_formats[format] = format_spec
        slice_class.define_parameter "#{format}_format_definition", definition[:definition]
        slice_class.send(:def_method, format.to_s) do ||
          definition % [self.value]
        end
      end
      slice_formats[:inspect] = slice_formats[default_format].merge(:name=>:inspect, :inspect=>true)
      slice_formats[:default] = slice_formats[default_format].merge(:name=>:default)

      format_definitions = slice_formats.inject({}){|hsh, kv| key, value = kv; hsh[key] = value[:definition]; hsh}
      format_widths  = slice_formats.inject({}){|hsh, kv| key, value = kv; hsh[key] = value[:max_width]; hsh}
      slice_class.define_collection "format_specification", slice_formats
      slice_class.define_collection "format_definition", format_definitions
      slice_class.define_collection "format_width",  format_widths
      slice_class.define_collection "format_type",   slice_formats.keys.sort_by{|f| f.to_s}
    
      # TODO: Allow for unpadded formatting, and types which are unpadded by default
      # TODO: Base inspect formatting on Class statically-defined inspect method?
      slice_class.send(:def_method, :format) do |*args|
        format_defn = args[0] || :default
        format = slice_formats[format_defn] if format_defn.is_a?(Symbol)
        if format
          format_definition = format[:definition]
          v = format[:string_format] ? self.string : self.value
          v = v.inspect if format[:inspect]
        else
          format_definition = format_defn || word_default_format # TODO '%p' would be better, but would cause endless recursion currently
          v = self.value
        end
        format_definition % [v]
      end
    
      slice_class.send(:def_method, :inspect) do ||
        format(:inspect)
      end
    
      unshifted_method_name = "unshifted_#{slice_name}"
      def_method unshifted_method_name do |n|
        value & masks[n]
      end
      
      if per_word == 1
        def_method slice_name do |*args|
          case args.size
          when 0
            n = 0
          when 1
            n = args.first
          else
            raise ArgumentError, "Wrong number of arguments for #{self.class}##{slice_name}() (#{args.size} of 0 or 1)"
          end
          slice_class.new(self.send(unshifted_method_name, n) >> shifts[n])
        end
      else
        def_method slice_name do |n|
          raise ArgumentError, "Nil index or wrong number of arguments for #{self.class}##{slice_name} (0 of 1)" if n.nil?
          slice_class.new(self.send(unshifted_method_name, n) >> shifts[n])
        end
      end
      def_method slices_name do ||
        # puts %Q{In #{self.name}##{slices_name}: self=#{self.inspect}\nCaller:\n#{caller.map{|s| "  "+s}.join("\n")}}
        ary = Slice::Array.new
        (0...per_word).each {|n| ary << self.send(slice_name, n) }
        ary
      end

      if is_string
        slice_class.def_method(:string) do ||
          self.chr
        end
        def_method "#{slice_name}_string" do |n|
          (0...per_word).map {|n| self.send(slice_name, n).string }
        end
      end
    end
    
    # A field only occurs once in a word
    # TODO Keep separate track of fields, vs. slices?
    # TODO Define structures (i.e. a sequence of fields -- possibly multiword?)
    def self.define_field(name, options={})
      define_slice(name, {:count=>1}.merge(options))
    end

    def clip(value)
      self.class.all_ones & value
    end
  
    # def value=(value)
    #   @value = clip(value)
    # end
  
    def bit_segment(from, to)
      value & make_bit_mask(from, to)
    end
  
    # TODO Allow negative indexing
    # TODO Consider a change which would permit indexing a la Array[]
    def get_bits(from, to)
      bit_segment(from, to) >> bit_count(to, size-1) # Use bit_count for extensibility
    end
    
    def bit_count(from, to)
      to - from + 1
    end
  
    def get_bit(at)
      get_bits(at, at)
    end
  
    def slice(n, size, offset=0)
      start = (n-1)*size + offset
      get_bits(start, start+size-1)
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
  
  module Container
    module ClassMethods
      def contains(klass)
        @@constituent_class = klass
      end
    
      def constituent_class
        @@constituent_class
      end
    
      def conform(data)
        case data
        when constituent_class, nil
          data
        else
          constituent_class.new(data)
        end
      end
      
      def [](*args)
        self.new(args)
      end
    end
    
    def self.included(base)
      base.extend(ClassMethods)
    end

    def constituent_class
      self.class.constituent_class
    end
    
    def conform(data)
      self.class.conform(data)
    end

    def initialize(data)
      super(data.map{|v| conform(v)})
    end

    def [](*args)
      segment = get_at(*args)
      case segment
      when constituent_class, nil
        segment # Do nothing
      when Array
        segment = self.class.new(segment)
      else 
        conform(segment)
      end
    end
    alias_method :slice, :[]

    def []=(*args)
      v = args.pop
      v = conform(v) unless v.nil? || v.is_a?(Array)
      args.push(v)
      set_at(*args)
    end
    
    def inspect
      "<#{self.class.name}[#{self.map{|e| e.inspect}.join(',')}]>"
    end
  end
  
  module WordArray
    def self.included(base)
      # puts "base=#{base.inspect}"
      # puts "base methods: #{base.instance_methods.sort.inspect}"
      base.send :alias_method, :get_at, :[] if !base.instance_methods.include?('get_at') && base.instance_methods.include?('[]')
      base.send :alias_method, :set_at, :[]= if !base.instance_methods.include?('set_at') && base.instance_methods.include?('[]=')
      base.send :include, Container
      class << base
        alias_method :old_contains, :contains
      end
      base.extend ClassMethods
    end
    
    module ClassMethods
      def slice_names
        @slice_names ||= []
      end
    
      def add_slice(name)
        @slice_names ||= []
        @slice_names << name
      end

      def contains(klass)
        old_contains(klass)
        add_slices(klass)
      end

      def add_slices(subclass)
        subclass.slice_names.each do |slice_name|
          add_slice slice_name
          # TODO This code is already written elsewhere. Refactor it
          slices_name = (slice_name.to_s + 's').to_sym
          per_word = subclass.send("#{slices_name}_per_word")
          # TODO Define singular slice(n) method
          define_method slices_name do
            @slices ||= {}
            unless @slices[slices_name]
              slices = []
              self.each do |w|
                slices += w.nil? ? [nil]*per_word : w.send(slices_name)
              end
              @slices[slices_name] = slices
            end
            @slices[slices_name]
          end
          define_method slice_name do |n|
            raise ArgumentError, "Wrong number of arguments for #{self.class}##{slice_name}() (0 of 1)" if n.nil?
            send(slices_name)[n]
          end
        end
      end
    end
    
    def slice_names
      self.class.slice_names
    end
  end
  
  def self.Words(constituent_class)
    klass = Class.new(Array)
    klass.send :include, Machine::WordArray
    klass.contains constituent_class
    klass
  end
  
  # TODO Make this dynamic with a defined constituent class, like Words
  # TODO Should Word be a mixin? WordsBase
  class MultiWord < Word
    include Container
    
    def get_at(*args)
      @data.[](*args)
    end
    
    def set_at(*args)
      @data.[]=(*args)
    end

    def word_size
      constituent_class.size
    end
    
    def size
      @data.size * word_size
    end
    
    def decode_index(index)
      index.split(":").map{|segment| segment.to_i}
    end
    
    def encode_index(*segments)
      segments.flatten.map{|segment| segment.to_s}.join(':')
    end

    # Indexes may be specified in one of three ways: as a bit number,
    # as a [word, bit] pair, or as a string "word:bit"
    def index_numeric(*index)
      index = index.flatten
      index = index.first if index.size == 1
      case index
      when Numeric
        index
      when Array
        index[0]*word_size + index[1]
      when String
        index_numeric(index_array(index))
      else
        raise IndexError, "Unknown index type (#{index.inspect})"
      end
    end
    
    def index_string(*index)
      index = index.flatten
      index = index.first if index.size == 1
      case index
      when Numeric
        index_string(index_array(index))
      when Array
        encode_index(*index)
      when String
        index
      else
        raise IndexError, "Unknown index type (#{index.inspect})"
      end
    end
    
    def index_array(*index)
      index = index.flatten
      index = index.first if index.size == 1
      case index
      when Numeric
        index.divmod(word_size)
      when Array
        index
      when String
        decode_index(index)
      else
        raise IndexError, "Unknown index type (#{index.inspect})"
      end
    end
    
    def index_class(klass, *index)
      case klass
      when Numeric
        index_numeric(*index)
      when Array
        index_array(*index)
      when String
        index_string(*index)
      else
        raise IndexError, "Unknown index type (#{index.inspect})"
      end
    end
    
    def bit_segment(from, to)
      from_word, from_bit = index_array(from)
      to_word, to_bit = index_array(to)
      words = (from_word..to_word).map {|i| self[i] }
      words[0] &= constituent_class.strip_leading_bit_masks[from_bit]
      words[-1] &= constituent_class.strip_trailing_bit_masks[to_bit]
      words.inject {|val, word| val<<word_size | word }
    end

    def get_bits(from, to)
      to_word, to_bit = index_array(to)
      bit_segment(from, to) >> bit_count(to_bit, word_size-1)
    end
    
    def bit_count(from, to)
      index_numeric(to) - index_numeric(from) + 1
    end
    
    def increment_index(index, increment)
      index_class(index, index_numeric(index)+1)
    end

    def slice(n, size, offset=0)
      size = index_numeric(size)
      offset = index_numeric(offset)
      start = (n-1)*size + offset
      get_bits(start, start+size-1)
    end
  end
end