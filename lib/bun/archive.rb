#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

require 'yaml'
require 'hashie/mash'
require 'lib/bun/file'

module Bun
  class Archive
    include Enumerable
    include CacheableMethods
    
    DIRECTORY_LOCATIONS = %w{location log_file raw_directory extract_directory files_directory clean_directory dirty_directory}
    OTHER_LOCATIONS = %w{repository catalog_file index_file}
    
    @@index = nil
    
    class << self
      include CacheableMethods
    
      def config_dir(name)
        dir = config[name]
        return nil unless dir
        dir = File.expand_path(dir) if dir=~/^~/
        dir
      end
  
      def config(config_file="data/archive_config.yml")
        @config = YAML.load(::File.read(config_file))
        @config['repository'] ||= ENV['BUN_REPOSITORY']
        @config
      end
      cache :config
    
      DIRECTORY_LOCATIONS.each do |locn|
        define_method locn do ||
          config_dir(locn)
        end
      end
      
      OTHER_LOCATIONS.each do |locn|
        define_method locn do ||
          config[locn]
        end
      end
    end
    
    attr_reader :location
    
    def initialize(location=nil)
      location = location[:archive] if location.is_a?(Hash)
      @location = location || self.class.location
    end
    
    def tapes(&blk)
      tapes = Dir.entries(File.join(location, raw_directory)).reject{|f| f=~/^\./}
      tapes.each(&blk) if block_given?
      tapes
    end
    alias_method :each, :tapes
    
    def each_file(&blk)
      tapes.each {|tape| open(tape, &blk)}
    end
    
    def config
      self.class.config
    end
    
    def config_dir(name)
      self.class.config_dir(name)
    end
    
    # TODO Are these necessary?
    (DIRECTORY_LOCATIONS - %w{location}).each do |locn|
      define_method locn do ||
        config_dir(locn)
      end
    end
    
    OTHER_LOCATIONS.each do |locn|
      define_method locn do ||
        File.expand_path(File.join(location, self.class.send(locn)))
      end
    end
    
    # TODO Is there a more descriptive name for this?
    def contents(&blk)
      tapes = self.tapes
      contents = []
      each do |tape_name|
        file = open(tape_name)
        if file.file_type == :frozen
          file.shard_count.times do |i|
            contents << "#{tape_name}::#{file.shard_name(i)}"
          end
        else
          contents << tape_name
        end
      end
      if block_given?
        contents.each(&blk)
      end
      contents
    end
    
    def expanded_tape_path(file_name)
      if file_name =~ /^\.\//
        rel = `pwd`.chomp
      else
        rel = File.expand_path(raw_directory, location)
      end
      File.expand_path(file_name, rel)
    end
    
    def catalog
      content = File.read(catalog_file)
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
    cache :catalog
    
    def catalog_time(tape)
      info = catalog.find {|spec| spec[:tape] == tape }
      info && info[:date].local_date_to_local_time
    end
    
    def index
      _index unless @@index
      @@index
    end
    
    def _index
      if File.exists?(index_file)
        @@index = YAML.load(File.read(index_file))
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
      FileUtils.rm(index_file)
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
    
    def descriptor(name, options={})
      # puts "In #{self.class}#descriptor(#{name.inspect}, #{options.inspect}): index[#{name.inspect}]=#{index[name].inspect}"
      if !exists?(name)
        nil
      elsif !options[:build] && index[name]
        Hashie::Mash.new(index[name])
        # index[name]
      else
        Hashie::Mash.new(build_descriptor(name))
        # build_descriptor(name)
      end
    end
    
    def open(name, options={}, &blk)
      File.open(expanded_tape_path(name), options.merge(:archive=>self, :tape_name=>name), &blk)
    end
    
    def exists?(name)
      File.exists?(expanded_tape_path(name))
    end
  end
end