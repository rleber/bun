class GECOS
  class File
    class Header < GECOS::File
      HEADER_SIZE = Descriptor.minimum_size
      
      def size
        HEADER_SIZE
      end
      
      def initialize(options={}, &blk)
        file = options[:file]
        data = options[:data]
        words = options[:words]
        words = if file
          words = self.class.decode(::File.read(file, Descriptor.minimum_size))
        elsif data
          words = self.class.decode(data[0...Descriptor.minimum_size])
        else
          words = words[0...Descriptor.minimum_size.div(characters_per_word)]
        end
        super(:words=>words, &blk)
      end
    end
  end
end
