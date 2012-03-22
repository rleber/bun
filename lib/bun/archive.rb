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
    OTHER_LOCATIONS = %w{repository catalog_file}
    
    # TODO Why is a class variable necessary here?
    
    class << self
      include CacheableMethods
    
      def config_dir(name)
        dir = config[name.to_s]
        return nil unless dir
        dir = File.expand_path(dir) if dir=~/^~/
        dir
      end
  
      def config(config_file="data/archive_config.yml")
        content = ::Bun.readfile(config_file, :encoding=>'us-ascii')
        @config = YAML.load(content)
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
    
    def initialize(options={})
      @location = options[:location] || options[:archive] || self.class.location
      @directory = options[:directory] || 'raw'
      @index = nil
      @update_indexes = options.has_key?(:update_indexes) ? options[:update_indexes] : true
    end
    
    def tapes(&blk)
      tapes = Dir.entries(File.join(location, directory_location)).reject{|f| f=~/^\./}
      tapes.each(&blk) if block_given?
      tapes
    end
    alias_method :each, :tapes
    
    def each_file(options={}, &blk)
      tapes.each do |tape| 
        open(tape, options, &blk)
      end
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
      
    def directory_location(directory=nil)
      directory ||= @directory
      config_dir("#{directory}_directory") || directory
    end
    
    OTHER_LOCATIONS.each do |locn|
      define_method locn do ||
        File.expand_path(File.join(location, self.class.send(locn)))
      end
    end
    
    def index_directory
      File.join(@location, directory_location, config['index_directory'])
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
        rel = File.expand_path(directory_location, location)
      end
      File.expand_path(file_name, rel)
    end
    
    def catalog
      content = Bun.readfile(catalog_file, :encoding=>'us-ascii')
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
      _index unless @index
      @index
    end
    
    def _index
      if File.directory?(index_directory)
        @index = {}
        Dir.glob(File.join(index_directory, '*.yml')) do |f|
          raise "Unexpected file #{f} in index #{index_directory}" unless f =~ /\.descriptor.yml$/
          file_name = File.basename($`)
          content = ::Bun.readfile(f, :encoding=>'us-ascii')
          @index[file_name] = YAML.load(content)
        end
      elsif File.exists?(index_directory)
        raise RuntimeError, "File #{index_directory} should be a directory"
      else
        build_and_save_index
      end
    end
    private :_index
    
    def build_and_save_index(options={})
      build_index(options)
    end
    
    def build_index(options={})
      clear_index
      each_file(:header=>true) do |f|
        puts f.tape_name if options[:verbose]
        update_index(:file=>f)
      end
      @index
    end
    
    def update_indexes=(value)
      @update_indexes = value
    end
    
    def update_indexes?
      @update_indexes
    end
    
    def with_update_indexes(value) # 
      original_update_indexes = @update_indexes
      @update_indexes = value
      begin
        yield
      ensure
        @update_indexes = original_update_indexes
      end
    end
    
    def clear_index
      clear_index_directory
      @index = nil
    end
    
    # TODO Allow for indexing by other than tape_name?
    def update_index(options={})
      @index ||= {}
      descr = options[:descriptor] ? options[:descriptor].to_hash : build_descriptor_for_file(options[:file])
      descr.keys.each do |k|
        if k.is_a?(String)
          descr[k.to_sym] = descr[k]
          descr.delete(k)
        end
      end
      @index[descr[:tape_name]] = descr
      save_index_descriptor(descr[:tape_name])
      descr
    end
    
    # TODO Is this being used anywhere?
    def build_descriptor(name)
      open(name, :header=>true) {|f| build_descriptor_for_file(f) }
    end
    
    def build_descriptor_for_file(f)
      entry = f.descriptor.to_hash
      entry
    end
    
    def clear_index_directory
      return unless @update_indexes
      FileUtils.rm_rf(index_directory)
    end
    
    def save_index
      clear_index_directory
      make_index_directory
      each do |name|
        _save_index_descriptor(name)
      end
      @index
    end
    
    def save_index_descriptor_for_file(f)
      @index ||= {}
      name = f.tape_name
      @index[name] ||= build_descriptor_for_file(f)
      make_index_directory
      _save_index_descriptor(name)
    end
    
    def save_index_descriptor(name)
      @index ||= {}
      @index[name] ||= build_descriptor(name)
      make_index_directory
      _save_index_descriptor(name)
    end
    
    def make_index_directory
      FileUtils.mkdir_p(index_directory) unless File.exists?(index_directory)
    end
    
    def _save_index_descriptor(name)
      return unless @update_indexes
      if RUBY_VERSION =~ /^1\.8/
        mode = 'w'
      else
        mode = 'w:us-ascii'
      end
      descriptor_file_name = File.join(index_directory, "#{name}.descriptor.yml")
      ::File.open(descriptor_file_name, mode) {|f| f.write @index[name].to_yaml }
    end
    private :_save_index_descriptor
    
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
    
    def cp(tape, dest=nil, options={})
      to_stdout = dest.nil? || dest == '-'
      index = !options[:bare] && !to_stdout
      unless to_stdout
        dest = '.' if dest == ''
        dest = File.join(dest, File.basename(tape)) if File.directory?(dest)
      end

      open(tape) do |f|
        Shell.new(:quiet=>true).write dest, f.read, :mode=>'w:ascii-8bit'
      end

      if index
        # Copy index entry, too
        to_dir = File.dirname(dest)
        to_archive = Archive.new(:location=>to_dir, :directory=>'')
        descriptor = self.descriptor(tape)
        descriptor.original_tape_name = tape unless descriptor.original_tape_name
        descriptor.original_tape_path = expanded_tape_path(tape) unless descriptor.original_tape_path
        descriptor.tape_name = File.basename(dest)
        descriptor.tape_path = File.expand_path(dest)
        to_archive.update_index(:descriptor=>descriptor)
      end
    end
  end
end