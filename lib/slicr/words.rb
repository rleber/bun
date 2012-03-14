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
        # import_by_chunks(content, 8, 'C*')
        import_by_chunks(content, 32, 'N*')
      end

      # This works and is about 12-15% faster than import_by_bytes
      def import_by_chunks(content, bits_per_chunk, unpack_mask)
        words = []
        accumulator = 0
        bits = 0
        width = constituent_class.width
        bytes_per_chunk = (bits_per_chunk+7).div(8)
        puts content.scan(/.{1,#{bytes_per_chunk}}/).inspect
        unless content.size % bytes_per_chunk == 0
          padding = "\0"*(bytes_per_chunk - content.size % bytes_per_chunk)
          content = content + padding 
        end
        puts content.scan(/.{1,#{bytes_per_chunk}}/).inspect
        chunks = content.unpack(unpack_mask)
        p chunks
        chunks.each do |chunk|
          accumulator <<= bits_per_chunk # Would checking for zero be faster?
          accumulator |= chunk
          bits += bits_per_chunk
          while bits >= width
            words << (accumulator >> (bits - width))
            accumulator &= (2**(bits-width)-1) # Mask off upper bits
            bits -= width 
          end
          puts "bits=#{bits}, accumulator=#{accumulator} words=#{words.inspect}"
        end
        if bits > 0
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
      
      # This works and is about 12-15% faster than import_by_bytes;
      # It is very slightly faster than import_by_chunks(content, 8, 'C*')
      def import_by_bytes_with_unpack(content)
        words = []
        accumulator = 0
        bits = 0
        width = constituent_class.width
        chunks = content.unpack("C*")
        chunks.each do |chunk|
          accumulator <<= 8
          accumulator |= chunk
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
      
      # This doesn't work
      def import_by_words(content)
        words = []
        accumulator = 0
        bits = 0
        width = constituent_class.width
        chunks = content.unpack("L*")
        chunks.each do |chunk|
          accumulator <<= 32
          accumulator |= chunk
          bits += 32
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
      
      # This doesn't work
      def import_by_quads(content)
        words = []
        accumulator = 0
        bits = 0
        width = constituent_class.width
        quads = content.unpack("Q*")
        quads.each do |q|
          accumulator <<= 64
          accumulator |= q
          bits += 64
          while bits >= width
            words << (accumulator >> (bits - width))
            accumulator &= (2**(bits-width)-1) # Mask off upper bits
            bits -= width 
          end
        end
        if bits > 0
          words << (accumulator << (width - bits))
        end
        puts words.size
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