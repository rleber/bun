class GECOS
  class File
    class Blocked < GECOS::File

      def words=(words)
        super
        if @words.nil?
          @deblocked_content = nil
        end
        words
      end
    
      # TODO Create a subclass File::Deblocked
      def deblocked_content
        @deblocked_content ||= deblock_content
      end
      
      def content
        deblocked_content
      end
    
      # TODO Build a capability in Slicr to do things like this
      def deblock_content
        deblocked_content = []
        offset = 0
        block_number = 1
        loop do
          break if offset >= file_content.size
          break if file_content[offset] == 0
          block_size = file_content[offset].byte[-1]
          raise "Bad block number #{block_number} in #{tape} at #{'%#o' % offset}: expected #{'%07o' % block_number}; got #{file_content[offset].half_word[0]}" unless file_content[offset].half_word[0] == block_number
          deblocked_content += file_content[offset+1..(offset+block_size)].to_a
          offset += 0500
          block_number += 1
        end
        GECOS::Words.new(deblocked_content)
      end
      private :deblock_content
    end
  end
end