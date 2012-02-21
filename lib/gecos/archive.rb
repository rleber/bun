require 'yaml'

class GECOS
  class Archive
    
    # INDEX_FILE = '.index'
    
    def self.location
      config['archive'].sub(/^~/,ENV['HOME'])
    end
    
    def self.raw_directory
      config['raw_directory'].sub(/^~/,ENV['HOME'])
    end
    
    # def self.index_file
    #   File.join(raw_directory, INDEX_FILE)
    # end
    
    def self.repository
      config['repository']
    end
    
    def self.load_config(config_file="data/archive_config.yml")
      @config = YAML.load(File.read(config_file))
      @config['repository'] ||= ENV['GECOS_REPOSITORY']
      @config
    end
    
    # Is the given file frozen?
    # Yes, if and only if it has a valid descriptor
    def self.frozen?(file_name)
      raise "File #{file_name} doesn't exist" unless File.exists?(file_name)
      return nil unless File.exists?(file_name)
      decoder = Decoder.new(File.read(file_name, 300))
      defroster = Defroster.new(decoder)
      descriptor = Defroster::Descriptor.new(defroster, 0, :allow=>true)
      descriptor.valid?
    end
    
    def self.config
      @config ||= load_config
    end
    
    attr_reader :location
    
    def initialize(location=nil)
      @location = location || self.class.location
    end
    
    def tapes
      Dir.entries(File.join(location, raw_directory)).reject{|f| f=~/^\./}
    end
    
    def raw_directory
      self.class.raw_directory
    end

    def file_path(tape_name)
      decoder = Decoder.new(File.read(qualified_tape_file_name(tape_name),300))
      decoder.file_path
    end
    
    def qualified_tape_file_name(file_name)
      file_name =~ /^\// ? file_name : File.join(location, raw_directory, file_name)
    end
    
    def config
      self.class.config
    end
  end
end

