require 'yaml'

class GECOS
  class Archive
    
    INDEX_FILE = '.index'
    LOG_FILE   = '.log'
    
    def self.location
      config['archive'].sub(/^~/,ENV['HOME'])
    end
    
    def self.raw_directory
      config['raw_directory'].sub(/^~/,ENV['HOME'])
    end
    
    def self.index_file
      File.join(raw_directory, INDEX_FILE)
    end
    
    def self.repository
      config['repository']
    end
    
    def self.load_config(config_file="data/archive_config.yml")
      @config = YAML.load(File.read(config_file))
      @config['repository'] ||= ENV['GECOS_REPOSITORY']
      @config
    end
    
    def self.config
      @config ||= load_config
    end
    
    attr_reader :location
    
    def initialize(location=nil)
      @location = location || self.class.location
    end
    
    def index
      @archive_index ||= _index
    end

    def _index(index_file=nil)
      index_file ||= self.class.index_file
      File.read(File.join(location,index_file)).split("\n").map{|line| line.split(/\s+/)}
    end

    def file_name(name)
      name = File.basename(name)
      line = index.find{|l| l[0] == name}
      return nil unless line
      line[-1]
    end
    
    def config
      self.class.config
    end
    
    def log(message)
      warn message
    end
  end
end

