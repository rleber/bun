class GECOS
  class File
    class Excerpt << GECOS::File
      def initialize(options={}, &blk)
        file = options[:file]
        data = options[:data]
        words = options[:words]
        words = if file
          words = decode(File.read(file, Descriptor.minimum_size))
        elsif data
          words = decode(data[0...Descriptor.minimum_size])
        else
          words = words[0...Descriptor.minimum_size.div(characters_per_word)]
        end
        super(:words=>words, &blk)
      end
    end
  end
end
