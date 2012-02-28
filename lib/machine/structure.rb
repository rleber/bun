require 'machine/masks'
require 'machine/formats'

module Machine
  class Structure < GenericNumeric
    
    FORMATS = Format.define(
      :binary=>         "%0#*b", 
      :octal=>          "%0#*o", 
      :decimal=>        "%*d",
      :hex=>            "%0#*x",
      :string=>         "%-*s",
      :string_inspect=> "%-*s"
    )
    
    @@single_bit_masks = Masks.new {|n| 1<<n }
    @@all_ones = Masks.new {|n| 2**n - 1 }
    
    class << self
      # TODO This stuff is repetitive; refactor it
      def single_bit_mask(n)
        @@single_bit_masks[n]
      end

      def all_ones(n)
        @@all_ones[n]
      end
  
      def make_bit_mask(width, from, to)
        leading_bit_mask = all_ones(width-from)
        trailing_bit_mask = all_ones(width) ^ all_ones(width-to)
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
        slice.add_formats(FORMATS)
        add_slice slice
    
        unshifted_method_name = "unshifted_#{slice.name}"
        def_method unshifted_method_name do |n|
          value & slice.masks[n]
        end
      
        if slice.count == 1
          def_method slice.name do |*args|
            case args.size
            when 0
              n = 0
            when 1
              n = args.first
            else
              raise ArgumentError, "Wrong number of arguments for #{self.class}##{slice.name}() (#{args.size} of 0 or 1)"
            end
            slice.data_class.new(self.send(unshifted_method_name, n) >> shifts[n])
          end
        else
          def_method slice.name do |n|
            raise ArgumentError, "Nil index or wrong number of arguments for #{self.class}##{slice.name} (0 of 1)" if n.nil?
            slice.data_class.new(self.send(unshifted_method_name, n) >> shifts[n])
          end
        end

        def_method slice.plural do ||
          # puts %Q{In #{self.name}##{slice.plural}: self=#{self.inspect}\nCaller:\n#{caller.map{|s| "  "+s}.join("\n")}}
          ary = Slice::Array.new
          (0...slice.count).each {|n| ary << self.send(slice.name, n) }
          ary
        end

        if slice.string?
          slice.data_class.def_method(:string) do ||
            self.chr
          end
          def_method "#{slice.name}_string" do |n|
            (0...slice.count).map {|n| self.send(slice.name, n).string }
          end
        end
      end
    
      # A field only occurs once in a word
      # TODO Keep separate track of fields, vs. slices?
      # TODO Define structures (i.e. a sequence of fields -- possibly multiword?)
      def define_field(name, options={})
        define_slice(name, {:count=>1}.merge(options))
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
      self.class.all_ones(size) & value
    end
  
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
  end
end