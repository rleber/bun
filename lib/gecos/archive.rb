require 'yaml'

class GECOS
  class Archive
    
    def self.config_dir(name)
      config[name].sub(/^~/,ENV['HOME'])
    end
    
    def self.location
      config_dir('archive')
    end
    
    def self.log_file
      config_dir('log_file')
    end
    
    def self.raw_directory
      config_dir('raw_directory')
    end
    
    def self.extract_directory
      config_dir('extract_directory')
    end
    
    def self.xref_directory
      config_dir('xref_directory')
    end
    
    def self.clean_directory
      config_dir('clean_directory')
    end
    
    def self.dirty_directory
      config_dir('dirty_directory')
    end
    
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
    
    def extract_directory
      self.class.extract_directory
    end
    
    def xref_directory
      self.class.xref_directory
    end

    def clean_directory
      self.class.clean_directory
    end

    def dirty_directory
      self.class.dirty_directory
    end
    
    def log_file
      self.class.log_file
    end
    
    def frozen?(file)
      self.class.frozen?(file)
    end

    def file_path(tape_name)
      decoder = Decoder.new(File.read(qualified_tape_file_name(tape_name),300))
      decoder.file_path
    end
    
    def contents
      tapes = self.tapes
      contents = []
      tapes.each do |tape_name|
        extended_file_name = qualified_tape_file_name(tape_name)
        if frozen?(extended_file_name)
          decoder = Decoder.new(File.read(extended_file_name))
          defroster = Defroster.new(decoder)
          defroster.file_paths.each_with_index do |path, i|
            file = defroster.file_name(i)
            contents << {:tape=>tape_name, :file=>file, :tape_and_file=>"#{tape_name}:#{file}", :path=>path}
          end
        else
          decoder = Decoder.new(File.read(extended_file_name))
          path = decoder.file_path
          contents << {:tape=>tape_name, :tape_and_file=>tape_name, :path=>path}
        end
      end
      contents
    end
    
    def qualified_tape_file_name(file_name)
      file_name =~ /^\// ? file_name : File.join(location, raw_directory, file_name)
    end
    
    def config
      self.class.config
    end
  end
end

