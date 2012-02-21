# TODO Either remove this entirely and retrieve index information from the individual files, or remove idallen references
class Fass
  class Archive

    ARCHIVE_LISTING = 'data/idallen.com/fass/honeywell_archiver/_misc/fass-index.txt'
    DEFAULT_ARCHIVE_DIRECTORY = "data/idallen.com/fass/honeywell_archiver/_misc/36_bit_tape_files"

    def self.default_directory
      DEFAULT_ARCHIVE_DIRECTORY
    end
    
    def self.index
      @archive_index ||= _index
    end

    def self._index
      File.read(ARCHIVE_LISTING).split("\n").map{|line| line.split(/\s+/)}
    end

    def self.file_name(name)
      name = File.basename(name)
      line = index.find{|l| l[0] == name}
      return nil unless line
      line[-1]
    end
  end
end

