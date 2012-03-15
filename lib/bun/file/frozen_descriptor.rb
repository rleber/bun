class Bun
  class File::Frozen::Descriptor
    attr_reader :file, :number

    DESCRIPTOR_OFFSET = 5
    DESCRIPTOR_SIZE = 10
    BLOCK_SIZE = 64  # 36-bit words
    DESCRIPTOR_END_MARKER = 0777777777777
    FIELDS = [
      :file_size,
      :file_type,
      :index_date,
      :name,
      :owner,
      :path,
      :tape_name,
      :tape_path,
      :update_date,
      :update_time,
      :updated,
    ]

    def self.offset
      DESCRIPTOR_OFFSET
    end

    def self.size
      DESCRIPTOR_SIZE
    end

    def self.end_marker
      DESCRIPTOR_END_MARKER
    end
  
    # Is a file frozen?
    # Yes, if and only if it has a valid descriptor
    def self.frozen?(file)
      file.words.at(file.content_offset + offset + size - 1) == end_marker
    end

    def initialize(file, number, options={})
      @file = file
      @number = number
      raise "Bad descriptor ##{number} for #{file.tape} at #{'%#o' % self.offset}:\n#{dump}" unless options[:allow] || valid?
    end
    
    def to_hash
      FIELDS.inject({}) {|hsh, f| hsh[f] = self.send(f) rescue nil; hsh }
    end

    def offset(n=nil) # Offset of the descriptor from the beginning of the file content, in words
      # TODO Optimize is n.nil? ever used
      n ||= number
      file.content_offset + DESCRIPTOR_OFFSET + n*DESCRIPTOR_SIZE
    end

    def finish
      offset(number+1)-1
    end
      
    def characters(start, length)
      @file.all_characters[offset*file.characters_per_word + start, length].join
    end

    def words(start, length)
      @file.words[start+offset, length]
    end

    def word(start)
      @file.words.at(start+offset)
    end

    def name
      characters(0,8).strip
    end
    
    def owner
      file.owner
    end
    
    def file_type
      :shard
    end

    def path
      File.relative_path(file.path, name)
    end
    
    def tape_name
      file.tape_name
    end
    
    def tape_path
      file.tape_path
    end

    def update_date
      File.date(_update_date)
    end

    def _update_date
      characters(8,8)
    end

    def update_time_of_day
      File.time_of_day(_update_time_of_day)
    end

    def _update_time_of_day
      word(4)
    end
    
    def index_date
      file.index_date
    end

    # TODO Choose earlier of this time or time of file
    def update_time
      File.time(_update_date, _update_time_of_day)
    end
    alias_method :updated, :update_time

    def blocks
      word(6).value
    end

    def self.block_size
      BLOCK_SIZE  # In words
    end

    def block_size
      self.class.block_size
    end

    def start
      word(7).value
    end

    def size
      word(8).value
    end
    alias_method :file_size, :size

    def valid?
      # TODO Optimize Is this check necessary?
      return nil unless finish < @file.words.size
      (check_text == 'asc ') && (check_word == DESCRIPTOR_END_MARKER)
    end

    def check_text
      characters(20,4)
    end

    def check_word
      word(9)
    end

    def hex
      words(offset, self.class.size).map{|w| '%#x' % w.value}.join(' ')
    end
    
    def dump
      octal + "\ncheck_text: #{check_text.inspect}, check_word: #{'%#o' % check_word}"
    end
    
    def octal
      words(0, self.class.size).map{|w| '%012o' % w.value}.join(' ')
    end
  end
end