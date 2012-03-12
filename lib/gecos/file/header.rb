class GECOS
  class File
    class Header < GECOS::File
      HEADER_SIZE = Descriptor.maximum_size
      
      # TODO Should read in two gulps: first to get the descriptor + one freeze file descriptor (if there), then get descriptors
      def size
        HEADER_SIZE
      end
      
      def initialize(options={}, &blk)
        file = options[:file]
        data = options[:data]
        words = options[:words]
        words = if file
          words = self.class.decode(::File.read(file, size))
        elsif data
          words = self.class.decode(data[0...size])
        else
          words = words[0...size.div(characters_per_word)]
        end
        super(:words=>words, &blk)
      end
    end
  end
end
