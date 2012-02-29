require 'machine/structure'

module Machine
  class Word < Structure
  
    FORMAT_WIDTH_WILDCARD = /<width>/
    # TODO Could this be improved using the '*' sprintf flag?
    # TODO Generalize the inspect thing
    # define_parameter :formats, {
    #   :binary=>         "%0#<width>b", 
    #   :octal=>          "%0#<width>o", 
    #   :decimal=>        "%<width>d",
    #   :hex=>            "%0#<width>x",
    #   :string=>         "%-<width>s",
    #   :string_inspect=> "%-<width>s",
    # }
    
    class << self
      def fixed_size?
        true
      end
      
      def size
        @size
      end
      
      def ones_mask(n=size)
        super(n)
      end
      
      def define_size(word_size)
        @size = word_size
      end
      
      def define_slice(slice_name, options={})
        slice_definition = super
        slice_definition.count = slice_count(slice_definition)
        slice_definition
      end
      
      # TODO Should this be in Structure?
      def slice_count(slice, offset=0, gap=0)
        case slice
        when Numeric
          slice_size = slice
          available_bits = size - offset
          bits_per_slice = [slice_size+gap, available_bits].min
          available_bits.div(bits_per_slice)
        when Slice::Definition
          if slice.count
            slice.count
          else
            slice_count(slice.size, slice.offset, slice.gap)
          end
        else # Assume it's a name
          defn = slice_definition(slice)
          defn && slice_count(defn)
        end
      end
      
      # TODO Should word.byte mean word.byte(0) or word.byte(n)?
      # TODO Should be recursive -- i.e. Should be able to say word.half_word(0).byte(2)
      # TODO Define bit and byte order (i.e. LR, RL)
      # TODO Define signs other than at the beginning of a slice
      # def define_slice(slice_name, options={})
      #   slice_name = slice_name.to_s.downcase
      #   slices_name = slice_name.pluralize
      #   slice_size = options[:size]
      #   slice_offset = options[:offset] || 0
      #   nbits = options[:bits] || slice_size
      #   clipping_mask = options[:mask] || n_bit_masks(nbits)
      #   is_string = !!options[:string]
      #   sign = options[:sign] || :none
      #   default_format = options[:default_format] || (is_string ? :string_inspect : (sign == :none ? :octal : :decimal))
      #   format_overrides = options[:format] || {}
      #   slice_gap = options[:gap] || 0
      #   per_word = options[:count]
      #     
      #   class_name = slice_name.gsub(/(^|_)(.)/) {|match| $2.upcase}
      #   if is_string
      #     parent = Slice::String
      #   else
      #     parent = case sign
      #     when :none then Slice::Unsigned
      #     when :ones_complement then Slice::Signed::OnesComplement
      #     when :twos_complement then Slice::Signed::TwosComplement
      #     else  
      #       raise ArgumentError, "Bad value for :sign (#{sign.inspect}). Should be one of #{VALID_SIGNS.inspect}"
      #     end
      #   end
      #   slice_class = Class.new(parent)
      #   const_set(class_name, slice_class)
      #   add_slice(slice_name, options.merge(:class=>slice_class))
      # 
      #   # TODO Refactor this stuff as a slice specification (size, gap, offset, etc.)
      #   per_word ||= slice_count(slice_size, slice_offset, slice_gap)
      #   start_bits = (0...per_word).map{|n| slice_start_bit(n, slice_size, slice_offset, slice_gap) }
      #   end_bits = (0...per_word).map{|n| slice_end_bit(n, slice_size, slice_offset, slice_gap) }
      #   shifts = end_bits.map{|end_bit| size - end_bit - 1 }
      # 
      #   masks = (0...per_word).map do |n|
      #     mask = slice_mask(n, slice_size, slice_offset, slice_gap)
      #     clip_to = (clipping_mask << (size - end_bits[n] - 1))
      #     res = mask & clip_to
      #   end
      #     
      #   define_parameter "#{slice_name}_size",              slice_size
      #   define_parameter "#{slice_name}_offset",            slice_offset
      #   define_parameter "#{slices_name}_per_word",         per_word
      #   define_parameter "#{slice_name}_significant_bits",  nbits
      #   define_parameter "#{slice_name}_string?",           is_string
      #   define_parameter "#{slice_name}_clipping_mask",     clipping_mask
      #     
      #   slice_class.define_parameter  "size",               slice_size
      #   slice_class.define_parameter  "offset",             slice_offset
      #   slice_class.define_parameter  "per_word",           per_word
      #   slice_class.define_parameter  "significant_bits",   nbits
      #   slice_class.define_parameter  "string?",            is_string
      #   slice_class.define_parameter  "clipping_mask",      clipping_mask
      # 
      #   # Again, all the bit masks have an extra entry
      #   slice_class.define_collection "single_bit_mask",    single_bit_masks[-(nbits+1)..-1]
      #   slice_class.define_collection "strip_leading_bit_mask", strip_leading_bit_masks[(nbits+1)..-1]
      #   slice_class.define_collection "strip_trailing_bit_mask", strip_trailing_bit_masks[0..nbits]
      #   slice_class.define_collection "n_bit_mask",         n_bit_masks[0..nbits]
      #   slice_class.define_collection "lower_bit_mask",     lower_bit_masks[0..nbits]
      #   slice_class.define_collection "upper_bit_mask",     upper_bit_masks[-(nbits+1)..-1]
      #   slice_class.define_parameter  "ones_mask",           ones_mask & clipping_mask
      # 
      # 
      #   define_collection "#{slice_name}_end_bit",   end_bits
      #   define_collection "#{slice_name}_start_bit", start_bits
      #   define_collection "#{slice_name}_shift",     shifts
      #   define_collection "#{slice_name}_mask",      masks
      # 
      #   slice_class.define_collection "end_bit",     end_bits
      #   slice_class.define_collection "start_bit",   start_bits
      #   slice_class.define_collection "shift",       shifts
      #   slice_class.define_collection "mask",        masks
      #     
      #   # TODO This method is too long. Refactor it
      #   slice_formats = {}
      #   formats.each do |format, definition|
      #     format_string = format.to_s
      #     string_format = format_string =~ /string/
      #     next if string_format && !is_string
      #     definition = format_overrides[format] if format_overrides[format]
      #     format_samples = [n_bit_masks[nbits], n_bit_masks[nbits-1]||0, n_bit_masks[0], 0]
      #     if !string_format && nbits == 1 # Special case for single bits (binary, octal, decimal, and hex representations are all the same)
      #       definition = definition.gsub(/%.*(?:#{FORMAT_WIDTH_WILDCARD})?.*?([a-z])/, '%\1')
      #     end
      #     sample_definition = definition.gsub(FORMAT_WIDTH_WILDCARD, '')
      #     format_samples = format_samples.map{|v| v.chr } if string_format && is_string
      #     sample_texts = format_samples.map{|v| sample_definition % [v] }
      #     width = sample_texts.map{|t| t.size}.max
      #     definition = definition.gsub(FORMAT_WIDTH_WILDCARD, width.to_s)
      #     format_spec = {:name=>format, :definition=>definition, :max_width=>width}
      #     format_spec[:inspect] = true if format_string =~ /inspect/
      #     format_spec[:string_format] = string_format
      #     slice_formats[format] = format_spec
      #     slice_class.define_parameter "#{format}_format_definition", definition[:definition]
      #     slice_class.send(:def_method, format.to_s) do ||
      #       definition % [self.value]
      #     end
      #   end
      #   slice_formats[:inspect] = slice_formats[default_format].merge(:name=>:inspect, :inspect=>true)
      #   slice_formats[:default] = slice_formats[default_format].merge(:name=>:default)
      # 
      #   format_definitions = slice_formats.inject({}){|hsh, kv| key, value = kv; hsh[key] = value[:definition]; hsh}
      #   format_widths  = slice_formats.inject({}){|hsh, kv| key, value = kv; hsh[key] = value[:max_width]; hsh}
      #   slice_class.define_collection "format_specification", slice_formats
      #   slice_class.define_collection "format_definition", format_definitions
      #   slice_class.define_collection "format_width",  format_widths
      #   slice_class.define_collection "format_type",   slice_formats.keys.sort_by{|f| f.to_s}
      #     
      #   # TODO: Allow for unpadded formatting, and types which are unpadded by default
      #   # TODO: Base inspect formatting on Class statically-defined inspect method?
      #   slice_class.send(:def_method, :format) do |*args|
      #     format_defn = args[0] || :default
      #     format = slice_formats[format_defn] if format_defn.is_a?(Symbol)
      #     if format
      #       format_definition = format[:definition]
      #       v = format[:string_format] ? self.string : self.value
      #       v = v.inspect if format[:inspect]
      #     else
      #       format_definition = format_defn || word_default_format # TODO '%p' would be better, but would cause endless recursion currently
      #       v = self.value
      #     end
      #     format_definition % [v]
      #   end
      #     
      #   slice_class.send(:def_method, :inspect) do ||
      #     format(:inspect)
      #   end
      #     
      #   unshifted_method_name = "unshifted_#{slice_name}"
      #   def_method unshifted_method_name do |n|
      #     value & masks[n]
      #   end
      # 
      #   if per_word == 1
      #     def_method slice_name do |*args|
      #       case args.size
      #       when 0
      #         n = 0
      #       when 1
      #         n = args.first
      #       else
      #         raise ArgumentError, "Wrong number of arguments for #{self.class}##{slice_name}() (#{args.size} of 0 or 1)"
      #       end
      #       slice_class.new(self.send(unshifted_method_name, n) >> shifts[n])
      #     end
      #   else
      #     def_method slice_name do |n|
      #       raise ArgumentError, "Nil index or wrong number of arguments for #{self.class}##{slice_name} (0 of 1)" if n.nil?
      #       slice_class.new(self.send(unshifted_method_name, n) >> shifts[n])
      #     end
      #   end
      #   def_method slices_name do ||
      #     # puts %Q{In #{self.name}##{slices_name}: self=#{self.inspect}\nCaller:\n#{caller.map{|s| "  "+s}.join("\n")}}
      #     ary = Slice::Array.new
      #     (0...per_word).each {|n| ary << self.send(slice_name, n) }
      #     ary
      #   end
      # 
      #   if is_string
      #     slice_class.def_method(:string) do ||
      #       self.chr
      #     end
      #     def_method "#{slice_name}_string" do |n|
      #       (0...per_word).map {|n| self.send(slice_name, n).string }
      #     end
      #   end
      # end
    end

    # def clip(value)
    #   self.class.ones_mask & value
    # end
    #   
    # # def value=(value)
    # #   @value = clip(value)
    # # end
    #   
    # def bit_segment(from, to)
    #   value & make_bit_mask(from, to)
    # end
    #   
    # # TODO Allow negative indexing
    # # TODO Consider a change which would permit indexing a la Array[]
    # def get_bits(from, to)
    #   bit_segment(from, to) >> bit_count(to, size-1) # Use bit_count for extensibility
    # end
    # 
    # def bit_count(from, to)
    #   to - from + 1
    # end
    #   
    # def get_bit(at)
    #   get_bits(at, at)
    # end
    #   
    def slice(n, size, offset=0, gap=0, width=nil)
      width ||= self.class.size
      super(n, size, offset, gap, width)
    end
  
    # def self.slices
    #   @slices ||=[]
    # end
    #   
    # def self.add_slice(name, definition)
    #   self.slices << definition.merge(:name=>name.to_sym)
    # end
    #   
    # def self.slice_names
    #   self.slices.map{|slice| slice[:name]}
    # end
  end
end