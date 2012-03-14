require 'lazy_array'

module Slicr
  
  def self.Words(constituent_class)
    klass = Class.new(Array)
    klass.send :include, Slicr::WordsBase
    klass.contains constituent_class
    klass
  end

  module WordsBase
    def self.included(base)
      if !base.instance_methods.include?('at') && base.instance_methods.include?('[]')
        base.send :alias_method, :at, :[] 
      end
      if !base.instance_methods.include?('set_at') && base.instance_methods.include?('[]=')
        base.send :alias_method, :set_at, :[]= 
      end
      base.send :include, Container
      base.send :include, Cacheable
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
        subclass.slices.each do |slice_name, slice_definition|
          raise NameError, "#{subclass.name} does not contain a slice #{slice_name}" unless slice_definition
          add_slice slice_name
          slices_name = slice_definition.plural
          slice_count = constituent_class.send(slice_name).count

          define_method slices_name do
            @slices ||= {}
            unless @slices[slices_name]
              slices = LazyArray.new do |index|
                self.send(slice_name, index)
              end
              slices.size = self.size * slice_count
              @slices[slices_name] = slices
            end
            @slices[slices_name]
          end

          define_method slice_name do |n|
            raise ArgumentError, "Wrong number of arguments for #{self.class}##{slice_name}() (0 of 1)" if n.nil?
            word, slice = n.divmod(slice_count)
            return nil if word >= self.size
            self[word].send(slice_name, slice)
          end
        end
      end
      
      # Import a Ruby string (of 8-bit characters) into words
      # def import(content)
      #   width = constituent_class.width
      #   case constituent_class.width % 8
      #   when 0
      #   when 4
      #   else
      #     import_by_bits(content)
      #   end
      # end
      def import(content)
        import_by_bytes_with_unpack(content) # Fastest so far
        # import_by_chunks(content, 8, 'C*') # Very slightly slower than import_by_bytes_with_unpack
        # import_by_chunks(content, 32, 'N*') # This is slightly slower than importing by C*
        # import_by_hex_nibbles(content, 4, 'H*')
        # import_by_hex_words(content)
      end
      
      # This works and is about 12-15% faster than import_by_bytes;
      # It is very slightly faster than import_by_chunks(content, 8, 'C*')
      def import_by_bytes_with_unpack(content)
        words = []
        accumulator = 0
        bits = 0
        width = constituent_class.width
        unless @import_divs
          @import_divs = Array(width+8)
          (width...(width+8)).each {|n| @import_divs[n] = 2**(n-width)}
          @import_masks = @import_divs.map{|div| div && div-1}
        end
        # The following is about as fast as I can make it in Ruby
        # Consider a native extension?
        chunks = content.unpack("C*")
        chunks.each do |chunk|
          accumulator = accumulator*256 + chunk
          bits += 8
          while bits >= width
            div = @import_divs[bits]
            words << accumulator.div(div)
            accumulator &= (div-1) # Mask off upper bits
            bits -= width 
          end
        end
        if bits > 0
          words << (accumulator<<(width-bits))
        end
        new(words)
      end
      
      # This works and is about 12-15% faster than import_by_bytes
      def import_by_chunks(content, bits_per_chunk, unpack_mask)
        words = []
        accumulator = 0
        bits = 0
        width = constituent_class.width
        bytes_per_chunk = (bits_per_chunk+7).div(8)
        padding_size = (bytes_per_chunk - content.size % bytes_per_chunk) % bytes_per_chunk
        content = content + "\0"*padding_size if padding_size > 0
        chunks = content.unpack(unpack_mask)
        chunks.each do |chunk|
          accumulator <<= bits_per_chunk # Would checking for zero be faster?
          accumulator |= chunk
          bits += bits_per_chunk
          while bits >= width
            words << (accumulator >> (bits - width))
            accumulator &= (2**(bits-width)-1) # Mask off upper bits
            bits -= width 
          end
          # puts "bits=#{bits}, accumulator=#{accumulator} words=#{words.inspect}"
        end
        if bits > padding_size*8
          words << (accumulator << (width - bits))
        end
        p words.size
        $count ||=0
        $count += 1
        if $count == 1
          p words
          exit
        end
        new(words)
      end
      
      # This is very slightly slower than import_by_bytes_with_unpack
      def import_by_hex_words(content)
        width = constituent_class.width
        hex = content.unpack('H*').first
        word_nibbles = width.div(4)
        word_pattern = /.{1,#{word_nibbles}}/
        words = hex.scan(word_pattern).map do |chunk|
          chunk = (chunk + '0'*word_nibbles)[0,word_nibbles] if chunk.size < word_nibbles
          words << Integer('0x' + chunk)
        end
        new(words)
      end

      def import_by_bytes(content)
        words = []
        accumulator = 0
        bits = 0
        width = constituent_class.width
        content.each_byte do |ch|
          accumulator <<= 8
          accumulator |= ch
          bits += 8
          while bits >= width
            words << (accumulator >> (bits - width))
            accumulator &= (2**(bits-width)-1) # Mask off upper bits
            bits -= width 
          end
        end
        if bits > 0
          words << (accumulator << (width - bits))
        end
        new(words)
      end
      
      # This is slower than import_by_bytes
      def import_by_hex_nibbles(content, bits_per_chunk, unpack_mask)
        words = []
        accumulator = 0
        bits = 0
        width = constituent_class.width
        bytes_per_chunk = (bits_per_chunk+7).div(8)
        padding_size = (bytes_per_chunk - content.size % bytes_per_chunk) % bytes_per_chunk
        content = content + "\0"*padding_size if padding_size > 0
        chunks = content.unpack(unpack_mask)
        chunks.first.scan(/./).each do |chunk|
          chunk = Integer('0x' + chunk)
          accumulator <<= bits_per_chunk # Would checking for zero be faster?
          accumulator |= chunk
          bits += bits_per_chunk
          while bits >= width
            words << (accumulator >> (bits - width))
            accumulator &= (2**(bits-width)-1) # Mask off upper bits
            bits -= width 
          end
          # puts "bits=#{bits}, accumulator=#{accumulator} words=#{words.inspect}"
        end
        if bits > padding_size*8
          words << (accumulator << (width - bits))
        end
        # p words.size
        # $count ||=0
        # $count += 1
        # if $count == 1
        #   p words
        #   exit
        # end
        new(words)
      end
      
      # This is slower than import_by_bytes
      def import_bits_by_unpack(content)
        width = constituent_class.width
        bits = content.unpack("B#{8*content.size}").first
        word_bits = (bits + '0'*width).scan(/.{#{width}}/) # Add the zeros to ensure a complete last word
        word_bits.pop # There will always be extra zeros at the end
        words = word_bits.map{|word| Integer('0b' + word)}
        new(words)
      end
      
      def read(file, options={})
        if file.is_a?(String)
          abort "File #{file} does not exist" unless ::File.exists?(file)
          file = ::File.open(file, 'rb')
          close_when_done = true
        end
        bytes = options[:n] ? (constituent_class.width * options[:n] + 8 - 1).div(8) : nil
        import(file.read(bytes))
      ensure
        file.close if close_when_done
      end
    end
    
    def slice_names
      self.class.slice_names
    end
  end
end