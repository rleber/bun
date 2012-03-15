require 'yaml'
require 'lib/bun/file'

class Bun
  class Archive
    include Enumerable
    
    @@index = nil
    
    def self.config_dir(name)
      dir = config[name]
      return nil unless dir
      dir = ::File.expand_path(dir) if dir=~/^~/
      dir
    end
    
    # TODO Use metaprogramming to refactor this
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
    
    def self.files_directory
      config_dir('files_directory')
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
    
    def self.original_index_file
      config['original_index_file']
    end

    def self.index_file
      config['index_file']
    end
    
    def self.load_config(config_file="data/archive_config.yml")
      @config = YAML.load(::File.read(config_file))
      @config['repository'] ||= ENV['BUN_REPOSITORY']
      @config
    end
    
    def self.config
      @config ||= load_config
    end
    
    attr_reader :location
    
    def initialize(location=nil)
      @location = location || self.class.location
    end
    
    def tapes
      Dir.entries(::File.join(location, raw_directory)).reject{|f| f=~/^\./}
    end
    
    def each_tape(&blk)
      tapes.each(&blk)
    end
    alias_method :each, :each_tape
    
    def each_file(&blk)
      tapes.each {|tape| open(tape, &blk)}
    end
    
    def raw_directory
      self.class.raw_directory
    end
    
    def extract_directory
      self.class.extract_directory
    end
    
    def files_directory
      self.class.files_directory
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
    
    def original_index_file
      ::File.expand_path(::File.join(location, self.class.original_index_file))
    end

    def index_file
      ::File.expand_path(::File.join(location, self.class.index_file))
    end
    
    # TODO Test me
    def contents
      tapes = self.tapes
      contents = []
      tapes.each do |tape_name|
        extended_file_name = expanded_tape_path(tape_name)
        if self.class.frozen?(extended_file_name)
          file = File.open(extended_file_name)
          # TODO is double open necessary?
          frozen_file = File::Frozen.open(extended_file_name)
          frozen_file.file_paths.each_with_index do |path, i|
            file = frozen_file.file_name(i)
            contents << {:tape=>tape_name, :file=>file, :tape_and_file=>"#{tape_name}:#{file}", :path=>path}
          end
        else
          file = File::Text.open(extended_file_name)
          path = file.file_path
          contents << {:tape=>tape_name, :tape_and_file=>tape_name, :path=>path}
        end
      end
      contents
    end
    
    def expanded_tape_path(file_name)
      if file_name =~ /^\.\//
        rel = `pwd`.chomp
      else
        rel = ::File.expand_path(raw_directory, location)
      end
      ::File.expand_path(file_name, rel)
    end
    
    def config
      self.class.config
    end
    
    def original_index
      @original_index ||= _original_index
    end
    
    def _original_index
      content = ::File.read(original_index_file)
      specs = content.split("\n").map do |line|
        words = line.strip.split(/\s+/)
        raise RuntimeError, "Bad line in index file: #{line.inspect}" unless words.size == 3
        # TODO Create a full timestamp (set to midnight)
        date = begin
          Date.strptime(words[1], "%y%m%d")
        rescue
          raise RuntimeError, "Bad date #{words[1].inspect} in index file at #{line.inspect}"
        end
        {:tape=>words[0], :date=>date, :file=>words[2]}
      end
      specs
    end
    private :_original_index
    
    def index_date(tape)
      info = original_index.find {|spec| spec[:tape] == tape }
      info && info[:date]
    end
    
    def index
      _index unless @@index
      @@index
    end
    
    def _index
      if ::File.exists?(index_file)
        @@index = YAML.load(::File.read(index_file))
      else
        build_and_save_index
      end
    end
    private :_index
    
    def build_and_save_index(options={})
      @@index = res = build_index(options)
      save_index(res)
      res
    end
    
    def build_index(options={})
      index = {}
      each_file do |f|
        puts f.tape_name if options[:verbose]
        index[f.tape_name] = build_descriptor_for_file(f)
      end
      index
    end
    
    def clear_index
      ::FileUtils.rm(index_file)
      @@index = nil
    end
    
    def build_descriptor(name)
      open(name, :header=>true) {|f| build_descriptor_for_file(f) }
    end
    
    def build_descriptor_for_file(f)
      entry = f.descriptor.to_hash
      entry[:shards] = (f.file_type == :frozen) ? f.shard_descriptors.map{|d| d.to_hash} : []
      entry
    end
    
    def save_index(index)
      ::File.open(index_file, 'w') {|f| f.write index.to_yaml }
    end
    
    # TODO Build an OpenStruct type object for descriptor
    def descriptor(name, options={})
      if !exists?(name)
        nil
      elsif !options[:build] && index[name]
        index[name]
      else
        build_descriptor(name)
      end
    end
    
    def open(name, options={}, &blk)
      File.open(expanded_tape_path(name), options.merge(:archive=>self, :tape_name=>name), &blk)
    end
    
    def exists?(name)
      ::File.exists?(expanded_tape_path(name))
    end
  end
end

