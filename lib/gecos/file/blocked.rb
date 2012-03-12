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
    
      alias_method :raw_content, :content
    
      # TODO Create a subclass File::Deblocked
      def content
        @deblocked_content ||= deblock_content
      end
    
      # TODO Build a capability in Slicr to do things like this
      def deblock_content
        deblocked_content = []
        offset = 0
        block_number = 1
        loop do
          break if offset >= raw_content.size
          break if raw_content[offset] == 0
          block_size = raw_content[offset].byte[-1]
          raise "Bad block number at #{'%#o' % offset}: expected #{'%06o' % block_number}; got #{raw_content[offset].half_word[0]}" unless raw_content[offset].half_word[0] == block_number
          deblocked_content += raw_content[offset+1..(offset+block_size)].to_a
          offset += 0500
          block_number += 1
        end
        GECOS::Words.new(deblocked_content)
      end
      private :deblock_content
    end
  end
end