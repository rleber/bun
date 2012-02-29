require 'machine/masks'
require 'machine/formats'
require 'machine/slice_accessor'

module Machine
  class Structure < GenericNumeric
    
    # TODO Move this to Formats module?
    FORMATS = Format.define(
      :binary=>         "%0#*b", 
      :octal=>          "%0#*o", 
      :decimal=>        "%*d",
      :hex=>            "%0#*x",
      :string=>         "%-*s",
      :string_inspect=> "%-*s"
    )

    include Formatted
    
    @@single_bit_masks = Masks.new {|n| 1<<n }
    @@ones_masks = Masks.new {|n| 2**n - 1 }
    
    class << self
      # TODO This stuff is repetitive; refactor it
      def single_bit_mask(n)
        @@single_bit_masks[n]
      end
      
      def single_bit_masks
        @@single_bit_masks
      end

      def ones_mask(n)
        @@ones_masks[n]
      end
      
      def ones_masks
        @@ones_masks
      end
  
      def make_bit_mask(width, from, to)
        leading_bit_mask = ones_mask(width-from)
        trailing_bit_mask = ones_mask(width) ^ ones_mask(width-to-1)
        leading_bit_mask & trailing_bit_mask
      end
  
      def slice_start_bit(n, size, offset=0, gap=0)
        n*(size+gap) + offset
      end
  
      def slice_end_bit(n, size, offset=0, gap=0)
        slice_start_bit(n+1, size, offset, gap) - gap - 1
      end
      
      def slice_shift(n, size, offset=0, gap=0)
        self.size - slice_end_bit(n, size, offset, gap) - 1
      end
  
      def slice_mask(n, size, offset=0, gap=0)
        make_bit_mask(slice_start_bit(n, size, offset, gap), slice_end_bit(n, size, offset, gap))
      end
  
      # TODO Should word.byte mean word.byte(0) or word.byte(n)?
      # TODO Should be recursive -- i.e. Should be able to say word.half_word(0).byte(2)
      # TODO Define bit and byte order (i.e. LR, RL)
      # TODO Define signs other than at the beginning of a slice
      def define_slice(slice_name, options={})
        slice = Slice::Definition.new(slice_name, self, options)
        slice.add_formats(nil, :format_overrides=>slice.formats, :default_format=>slice.default_format)
        add_slice slice
    
        unshifted_method_name = "unshifted_#{slice.name}"
        def_method unshifted_method_name do |n|
          value & slice.masks[n]
        end
      
        def_method slice.name do |*args|
          accessor = Slice::Accessor.new(slice, self)
          if args.size == 0
            accessor
          else
            accessor.[](*args)
          end
        end

        def_method slice.plural do ||
          Slice::Accessor.new(slice, self).s
        end

        if slice.string?
          slice.data_class.def_method(:string) do ||
            self.chr
          end
        end

        slice
      end
      
      # A field only occurs once in a word
      # TODO Keep separate track of fields, vs. slices?
      # TODO Define structures (i.e. a sequence of fields -- possibly multiword?)
      def define_field(name, options={})
        define_slice(name, {:count=>1, :collapse=>true}.merge(options))
      end

      def slices
        @slices ||=[]
      end

      def add_slice(definition)
        self.slices << definition
      end

      def slice_names
        self.slices.map{|slice| slice.name}
      end
      
      def slice_definition(slice_name)
        self.slices.find{|definition| definition.name == slice_name}
      end
      
      def fixed_size?
        false
      end
    end
    
    def size
      @data.size * constituent_class.size
    end

    def slice_count(slice_size, offset=0, gap=0)
      available_bits = size - offset
      bits_per_slice = [slice_size+gap, available_bits].min
      available_bits.div(bits_per_slice)
    end

    def clip(value)
      self.class.ones_mask(size) & value
    end
  
    def bit_segment(from, to, width=nil)
      width ||= size
      value & self.class.make_bit_mask(width, from, to)
    end
  
    # TODO Allow negative indexing
    # TODO Consider a change which would permit indexing a la Array[]
    def get_bits(from, to, width=nil)
      width ||= size
      bit_segment(from, to, width) >> bit_count(to, width-1)-1 # Use bit_count for extensibility
    end
    
    def bit_count(from, to)
      to - from + 1
    end
  
    def get_bit(at, width=nil)
      get_bits(at, at, width)
    end
  
    def slice(n, size, offset=0, gap=0, width=nil)
      start = n*(size+gap) + offset
      get_bits(start, start+size-1, width)
    end
  end
end