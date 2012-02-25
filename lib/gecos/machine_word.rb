# Class for defining generic machine words

class Object
  def singleton_class
    class << self; self; end
  end
end

class Class
  def define_class_method(name, &block)
    singleton_class.instance_eval do
      define_method(name) do
        yield
      end
    end
  end

  def define_parameter(name, value=nil, &blk)
    value = yield if block_given?
    const_set name.to_s.upcase, value
    define_method(name.to_s.downcase) { value }
    singleton_class.instance_eval do
      define_method(name.to_s.downcase) { value }
    end
    value
  end
  
  def define_array_parameter(name, value=nil, &blk)
    name = name.to_s.downcase
    value = define_parameter(name+"s", value, &blk)
    define_method name do |n|
      self.send(name+"s")[n]
    end
    singleton_class.instance_eval do
      define_method(name.to_s.downcase) {|n| self.send(name+"s")[n] }
    end
  end
  
  def define_hash_parameter(name, value=nil, &blk)
    define_array_parameter(name, value, &blk)
  end
  
  def define_class(name)
  end
end

class GenericNumeric

  attr_accessor :value
  
  def initialize(value)
    self.value = value
  end
  
  def method_missing(name, *args, &blk)
    ret = @value.send(name, *args, &blk)
    ret.is_a?(Numeric) ? self.class.new(ret) : ret
  end
end

class MachineWord < GenericNumeric
  
  FORMAT_WIDTH_WILDCARD = /<width>/
  define_parameter :formats, {
    :binary=>  "%0<width>#b", 
    :octal=>   "%0<width>#o", 
    :decimal=> "%<width>d",
    :hex=>     "%0<width>#x",
  }
  
  def self.define_size(word_size)
    ones = eval('0b' + ('1'*word_size))
    single_bit_masks    = (0...word_size).map {|n| 1<<n }.reverse
    preceding_bit_masks = (0..word_size).map {|n| ones>>n }
    following_bit_masks = (0..word_size).map {|n| ones & (ones << n) }
    lower_bit_masks     = preceding_bit_masks.reverse
    n_bit_masks         = lower_bit_masks
    upper_bit_masks     = following_bit_masks.reverse

    define_parameter :size, word_size
    define_parameter :all_ones, ones
    
    define_array_parameter :single_bit_mask,    single_bit_masks
    define_array_parameter :preceding_bit_mask, preceding_bit_masks
    define_array_parameter :following_bit_mask, following_bit_masks
    define_array_parameter :n_bit_mask,         n_bit_masks
    define_array_parameter :lower_bit_mask,     lower_bit_masks
    define_array_parameter :upper_bit_mask,     upper_bit_masks
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
  
  def self.define_slice(slice_name, options={})
    slice_name = slice_name.to_s.downcase
    slice_size = options[:size]
    slice_offset = options[:offset] || 0
    bits = options[:bits] || slice_size
    clipping_mask = options[:mask] || n_bit_masks[bits]
    default_format = options[:format] || :octal
    # TODO Define :sign option: :none, :ones_complement, :twos_complement
    # TODO Define fields (i.e. non-repeating parts of a word)
    # TODO Define structures (i.e. a sequence of fields -- possibly multiword?)
    
    class_name = slice_name.gsub(/(^|_)(.)/) {|match| $2.upcase}
    slice_class = Class.new(GenericNumeric)
    const_set(class_name, slice_class)
    slice_class.send(:define_method, :initialize) do |value|
      @value = value
    end
    slice_class.send(:attr_accessor, :value)
    
    per_word = slices_per_word(slice_size, slice_offset)
    start_bits = (0...per_word).map{|n| slice_start_bit(n, slice_size, slice_offset) }
    end_bits = (0...per_word).map{|n| slice_end_bit(n, slice_size, slice_offset) }
    shifts = end_bits.map{|end_bit| size - end_bit - 1 }
    masks = (0...per_word).map {|n| slice_mask(n, slice_size, slice_offset) & (clipping_mask << (size - end_bits[n] - 1)) }
    
    define_parameter "#{slice_name}_size",            slice_size
    define_parameter "#{slice_name}_offset",          slice_offset
    define_parameter "#{slice_name}s_per_word",       per_word
    define_parameter "#{slice_name}_clipping_mask",   clipping_mask
    
    slice_class.define_parameter "size",              slice_size
    slice_class.define_parameter "offset",            slice_offset
    slice_class.define_parameter "per_word",          per_word
    slice_class.define_parameter "clipping_mask",     clipping_mask
    
    define_array_parameter "#{slice_name}_end_bit",   end_bits
    define_array_parameter "#{slice_name}_start_bit", start_bits
    define_array_parameter "#{slice_name}_shift",     shifts
    define_array_parameter "#{slice_name}_mask",      masks

    slice_class.define_array_parameter "end_bit",     end_bits
    slice_class.define_array_parameter "start_bit",   start_bits
    slice_class.define_array_parameter "shift",       shifts
    slice_class.define_array_parameter "mask",        masks
    
    slice_formats = formats.dup
    slice_formats.each do |format, definition|
      sample_definition = definition.gsub(FORMAT_WIDTH_WILDCARD, '')
      sample_text = sample_definition % n_bit_masks[bits]
      width = sample_text.size
      definition = definition.gsub(FORMAT_WIDTH_WILDCARD, width.to_s)
      slice_formats[format] = definition
      slice_class.define_parameter "#{format}_format_string", definition
      slice_class.send(:define_method, format.to_s) do
        definition % self
      end
    end
    slice_formats[:default] = slice_formats[default_format]
    
    if options[:string]
      slice_formats[:inspect] = slice_formats[:octal] + ' %c'
    else
      slice_formats[:inspect] = slice_formats[:default]
    end
    slice_class.define_hash_parameter "format_string", slice_formats
    
    slice_class.send(:define_method, :format) do |*args|
      (args[0] || slice_formats[:default]) % self
    end
    
    slice_class.send(:define_method, :inspect) do
      slice_formats[:inspect] % self
    end
    
    unshifted_method_name = "unshifted_#{slice_name}"
    define_method unshifted_method_name do |n|
      value & masks[n]
    end
    
    define_method slice_name do |n|
      slice_class.new(self.send(unshifted_method_name, n) >> shifts[n])
    end
    define_method "#{slice_name}s" do
      (0...per_word).map {|n| self.send(slice_name, n) }
    end

    if options[:string]
      slice_class.send(:define_method, :string) do |n|
        self.chr
      end
      define_method "#{slice_name}_string" do |n|
        (0...per_word).map {|n| self.send(slice_name, n).string }
      end
    end
  end

  def clip(value)
    self.class.all_ones & value
  end
  
  # TODO Coerce to numeric or string value 
  
  def value=(value)
    @value = clip(value)
  end
  
  def unshifted_bits(from, to)
    value & bit_mask(from, to)
  end
  
  def bits(from, to)
    unshifted_bits(from, to) >> (size - to)
  end
  
  def slice(n, size, offset=0)
    start = (n-1)*size + offset
    bits(start, start+size-1)
  end
end
