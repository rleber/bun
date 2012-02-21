class Fass
  class Archive

    INDEX_FILE = 'fass-index.txt'
    DEFAULT_ARCHIVE_DIRECTORY = "_misc/36_bit_tape_files"

    
    def self.location
      config['archive']
    end
    
    def self.index
      @archive_index ||= _index
    end

    def self._index
      File.read(File.join(location,INDEX_FILE).split("\n").map{|line| line.split(/\s+/)}
    end

    def self.file_name(name)
      name = File.basename(name)
      line = index.find{|l| l[0] == name}
      return nil unless line
      line[-1]
    end
    
    def self.load_config(config_file="data/archive_config.yml")
      @config = YAML.load(File.read(config_file))
      @config['repository'] ||= ENV['GECOS_REPOSITORY']
      @config
    end
    
    def self.config
      @config ||= load_config
    end
    
    def config
      self.class.config
    end
  end
end

