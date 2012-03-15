require 'slicr/formats'
require 'slicr/slice'

module Slicr
  module Sliceable
    
    def self.included(base)
      base.send :include, Formatted
      base.extend(ClassMethods)
    end
    
    module ClassMethods
      def slice_count(slice_size, options={})
        data_size=options[:data_size]
        offset = options[:offset] || 0
        gap = options[:gap] || 0
        return nil unless data_size
        available_bits = data_size - offset
        bits_per_slice = slice_size+gap
        bits_per_slice = available_bits if bits_per_slice > available_bits && options[:partial]
        available_bits.div(bits_per_slice)
      end
      
      # TODO Should word.byte mean word.byte(0) or word.byte(n)?
      # TODO Should be recursive -- i.e. Should be able to say word.half_word(0).byte(2)
      # TODO Define bit and byte order (i.e. LR, RL)
      # TODO Define signs other than at the beginning of a slice
      def slice(slice_name, options={}, &blk)
        slice = Slice::Definition.new(slice_name, self, options, &blk)
        slice.install_formats
        add_slice slice
    
        _self = self
        def_class_method slice.name do ||
          Slice::Accessor.new(slice, _self)
        end
      
        def_method slice.name do |*args|
          accessor = Slice::Accessor.new(slice, self)
          args.size==0 ? accessor : accessor.at(args[0])
        end
        
        def_method slice.plural do ||
          Slice::Accessor.new(slice, self).to_a
        end

        if slice.string?
          slice.slice_class.def_method(:string) do ||
            self.chr
          end
        end

        slice
      end
      
      # A field only occurs once in a word
      # Fields also "collapse" - that is, if sign_bit is a field, then foo.sign_bit.binary
      # is possible -- it isn't necessary to say foo.sign_bit(0).binary
      # TODO Keep separate track of fields, vs. slices?
      # TODO Define structures (i.e. a sequence of fields -- possibly multiword?)
      def field(name, options={}, &blk)
        slice(name, {:count=>1, :collapse=>true}.merge(options), &blk)
      end
      
      def slices
        @slices
      end

      def add_slice(definition)
        @slices ||={}
        @slices[definition.name] = definition
      end
    end
    
    def slices
      self.class.slices
    end

    def width
      @data.size * constituent_class.width
    end
    
    # TODO Optimize Try this with value.unpack('B*')[start_bit,size], etc.
    def get_slice(n, size, offset, width)
      start_bit = n*size + offset
      next_bit = start_bit+size
      leading_bit_mask = 2**size-1
      value.div(2**(width-next_bit)) & leading_bit_mask
    end
  end
end