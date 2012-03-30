#!/usr/bin/env rvm-ruby 1.9.3
# -*- encoding: us-ascii -*-

require 'yaml'
require 'hashie/mash'
require 'lib/bun/file'
require 'lib/bun/archive_enumerator'
require 'date'

module Bun
  class Archive
    include Enumerable
    include CacheableMethods
    
    class NonRecursiveRemoveDirectory < ArgumentError; end
    class CopyDirectoryNonRecursive < ArgumentError; end
    class CopyMissingFromFile < ArgumentError; end
    class CopyToNonDirectory < ArgumentError; end
    
    attr_reader :at
    
    def initialize(options={})
      @at = File.expand_path(options[:at] || default_at)
      @index = nil
      @update_indexes = options.has_key?(:update_indexes) ? options[:update_indexes] : true
    end
    
    def locations
      Dir.entries(at).reject{|f| f=~/^\./}
    end

    def each(&blk)
      locations = self.locations
      enum = Enumerator.new(self)
      if block_given?
        enum.each(&blk)
      else
        enum
      end
    end
    
    def each_file(options={}, &blk)
      each.files(options, &blk)
    end
    
    def glob(*pat, &blk)
      each.glob(*pat, &blk)
    end
    
    def default_at
      File.expand_path(default_config['at'])
    end

    def config_dir(name)
      dir = config[name.to_s]
      return nil unless dir
      dir = File.expand_path(dir) if dir=~/^(~|\.)\//
      dir
    end
    
    def default_config_file
      File.expand_path(File.join(File.dirname(__FILE__), '..','..','data','archive_config.yml'))
    end
    
    def read_config_file(config_file)
      content = ::Bun.readfile(config_file, :encoding=>'us-ascii')
      config = YAML.load(content)
      config['repository'] ||= ENV['BUN_REPOSITORY']
      config
    end
    
    def default_config
      read_config_file(default_config_file)
    end
    cache :default_config
    
    def config(config_file=nil)
      return read_config_file(config_file) if config_file && File.file?(config_file)
      config_file = File.join(@at, '.config.yml')
      return read_config_file(config_file) if File.file?(config_file)
      default_config
    end
    cache :config
    
    def expanded_config(name)
      expand_path(config[name.to_s])
    end
    
    CONFIG_FILES = %w{log_file catalog_file index_directory}
    
    CONFIG_FILES.each do |item|
      define_method item do ||
        expanded_config(item)
      end
    end
    
    # TODO Is there a more descriptive name for this?
    def contents(&blk)
      locations = self.locations
      contents = []
      each do |location|
        file = open(location)
        if file.file_type == :frozen
          file.shard_count.times do |i|
            contents << "#{location}::#{file.shard_name(i)}"
          end
        else
          contents << location
        end
      end
      if block_given?
        contents.each(&blk)
      end
      contents
    end
    
    def expand_path(location, options={})
      if options[:from_wd] # Expand relative to working directory
        case location
        when /^@\/(.*)/ # syntax @/xxxx means expand relative to archive
               return expand_path($1)
        when /^\\(@.*)/ # syntax \@xxxx means ignore the '@'; expand relative to working directory
          location = $1
        end
        rel = `pwd`.chomp
      else # expand relative to archive
        rel = File.expand_path(at)
      end
      File.expand_path(location, rel)
    end
    
    def relative_path(*f)
      File.relative_path(*f, :relative_to=>at)
    end
    
    def catalog
      content = Bun.readfile(catalog_file, :encoding=>'us-ascii')
      return [] unless content
      specs = content.split("\n").map do |line|
        words = line.strip.split(/\s+/)
        raise RuntimeError, "Bad line in index file: #{line.inspect}" unless words.size == 3
        # TODO Create a full timestamp (set to midnight)
        date = begin
          Date.strptime(words[1], "%y%m%d")
        rescue
          raise RuntimeError, "Bad date #{words[1].inspect} in index file at #{line.inspect}"
        end
        {:location=>words[0], :date=>date, :file=>words[2]}
      end
      specs
    end
    cache :catalog
    
    def catalog_time(location)
      info = catalog.find {|spec| spec[:location] == location }
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
        puts f.location if options[:verbose]
        update_index(:file=>f)
      end
      if options[:recursive]
        directories do |f|
          sub_archive = Archive.new(:at=>expand_path(f))
          sub_archive.build_index(options)
        end
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
    
    # TODO Allow for indexing by other than location?
    def update_index(options={})
      @index ||= {}
      descr = options[:descriptor] ? options[:descriptor].to_hash : build_descriptor_for_file(options[:file])
      descr.keys.each do |k|
        if k.is_a?(String)
          descr[k.to_sym] = descr[k]
          descr.delete(k)
        end
      end
      @index[descr[:location]] = descr
      save_index_descriptor(descr[:location])
      descr
    end
    
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
      name = f.location
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
      descriptor_file_name = File.join(index_directory, "#{name}.descriptor.yml")
      # TODO This trap code was inserted to catch a tricky little bug; I'm leaving it here for awhile
      # if name == 'ar145.2699' && @index[name][:updated].nil?
      #   puts "_save_index_descriptor(#{name.inspect}): index=#{@index[name].inspect}"
      #   raise RuntimeError, ":updated == nil"
      # end
      ::File.open(descriptor_file_name, 'w:us-ascii') {|f| f.write @index[name].to_yaml }
    end
    private :_save_index_descriptor
    
    def descriptor(name, options={})
      if !exists?(name)
        nil
      elsif !options[:build] && index[name]
        Hashie::Mash.new(index[name])
      elsif options[:build] == false
        nil
      else
        Hashie::Mash.new(build_descriptor(name))
      end
    end
    
    def open(name, options={}, &blk)
      File.open(expand_path(name), options.merge(:archive=>self, :location=>name), &blk)
    end
    
    def exists?(name)
      File.exists?(expand_path(name))
    end
    
    def rm(options={})
      glob(*options[:locations]) do |fname|
        path = expand_path(fname)
        rm_at_path(path, options)
      end
    end
    
    def rm_at_path(path, options={})
      if File.directory?(path)
        raise NonRecursiveRemoveDirectory, "#{path} is a directory, but not recursive" unless options[:recursive]
        FileUtils.rm_rf(path)
      else
        FileUtils.rm(path)
        descriptor_file_name = File.join(File.dirname(path), config['index_directory'], "#{File.basename(path)}.descriptor.yml")
        puts "In Archive#rm_at_path: path=#{path.inspect}, descriptor_file_name=#{descriptor_file_name.inspect}"
        FileUtils.rm(descriptor_file_name) if File.exists?(descriptor_file_name)
      end
    end
    private :rm_at_path
    
    # cp follows the same rules as Unix cp:
    #   Notes: 
    #      - expand glob patterns first
    #      - file paths are expanded: from files, relative to archive; to files, relative to working
    #        directory. In the case of to files, '@/xxx' syntax is allowed, which forces expansion relative
    #        to archive
    #      - special values are allowed for to: nil or '-' causes output to go to STDOUT
    #      - options:
    #        :bare      Do not also copy bun index entries
    #        :quiet     Do not print warnings (use with :tolerant)
    #        :tolerant  Do not raise an exception on non-recursive copy of a directory -- just skip it
    #   1. cp [-r] file dest  (-r is irrelevant):
    #     a. if dest is omitted or '-'
    #        - copy file to STDOUT
    #     b. if dest does not exist:
    #        - copy file to dest
    #     c. if dest is a directory:
    #        - copy file to dest/file
    #        - dest/file is overwritten if it exists
    #     d. otherwise (dest exists and it is a file)
    #        - copy file to dest, overwriting it
    #   2. cp [-r] file dest/ (-r is irrelevant)
    #     - dest must exist and be a directory
    #     - if so, same as 1(c)
    #   3. cp [-r] directory file (-r is irrelevant)
    #      - fails
    #   4. cp directory dest_directory
    #      - does nothing: ignores from directory, with a warning
    #   5. cp -r directory dest_directory (with optional trailing /)
    #      a. if dest exists, copy directory (and its contents) to dest_directory/directory
    #      b. if dest does not exist, copy directory (and its contents) to dest_directory
    #   6. cp [-r] file_or_directory file_or_directory... dest_directory (with optional trailing /)
    #      a. if dest is omitted or '-'
    #         - Copy all files to STDOUT
    #      b. Otherwise, dest_directory must exist and be a directory
    #         - if not -r, ignore all directories in from list (with a warning)
    #         - Will not copy a directory into itself (e.g. cp -r dir dir)
    #         - Copies all files and directories into dest_directory
    def cp(options={})
      from = options[:from]
      from_list = glob(*from).to_a
      to = options[:to]
      to_path = to
      to_path = expand_path(to_path, :from_wd=>true) unless to.nil? || to == '-'
      if from_list.size == 1
        cp_single_file_or_directory(options.merge(:from=>from_list.first, :to=>to_path))
      else
        if to && to != '-'
          to += '/' unless to =~ %r{/$/}
        end
        from_list.each do |from_item|
          cp_single_file_or_directory(options.merge(:from=>from_item, :to=>to_path))
        end
      end
    end
    
    # Handles copying a single file or directory. Paths for :to should already
    # be expanded, but not :from
    def cp_single_file_or_directory(options={})
      from = options[:from]
      from_path = expand_path(from)
      to = options[:to]
      if to.to_s =~ %r{(.*)/$}
        to = $1
        raise CopyToNonDirectory, "#{to} is not a directory" unless File.directory?(to)
      end
      case
      when File.directory?(from_path)
        if to && to != '-'
          if File.exists?(to)
            raise CopyToNonDirectory, "#{to} is not a directory" unless File.directory?(to)
            creating_to_directory = false
          else
            creating_to_directory = true
          end
        end
        if options[:recursive]
          Dir.glob("#{from_path}/**/*") do |from_item|
            suffix = File.relative_path(from_item, :relative_to=>from_path)
            suffix = File.join(from, suffix) unless creating_to_directory
            target_dir = File.dirname(File.join(to, suffix))
            FileUtils.mkdir_p(target_dir)
            cp_single_file(options.merge(:from=>from_item, :to=>target_dir + '/'))
          end
        else
          if options[:tolerant]
            STDERR.puts "cp: Skipping directory #{from}" unless options[:quiet]
          else
            raise CopyDirectoryNonRecursive, "Can't non-recursively copy directory #{from}"
          end
        end
      when File.exists?(from_path)
        cp_single_file(options.merge(:from=>from_path))
      else
        raise CopyMissingFromFile, "#{from} does not exist"
      end
    end
    private :cp_single_file_or_directory
    
    # Copy a single file (no directories). :to may be a directory. Both from and to should be expanded
    def cp_single_file(options={})
      from = options[:from]
      to = options[:to]
      raise RuntimeError, "#{from} should not be a directory" if File.directory?(from)
      if to.to_s =~ %r{(.*)/$}
        to = $1
        raise CopyToNonDirectory, "#{to} is not a directory" unless File.directory?(to)
      end
      if to && to != '-' && File.directory?(to)
        to = File.join(to, File.basename(from))
      end
      cp_file_to_file(:from=>from, :to=>to, :bare=>options[:bare])
    end
    private :cp_single_file
    
    # Copy a single file to a file location. If the file already exists, it
    # is overwritten. 
    def cp_file_to_file(options={})
      from = options[:from]
      to = options[:to]
      to_stdout = to.nil? || to == '-'
      index = !options[:bare] && !to_stdout
      unless to_stdout
        to = '.' if to == ''
        to = File.join(to, File.basename(from)) if File.directory?(to)
      end

      open(from) do |f|
        Shell.new(:quiet=>true).write to, f.read, :mode=>'w:ascii-8bit'
      end

      if index
        # Copy index entry, too
        to_dir = File.dirname(to)
        to_archive = Archive.new(:at=>to_dir)
        descriptor = self.descriptor(File.basename(from))
        descriptor.original_location = File.basename(from) unless descriptor.original_location
        descriptor.original_location_path = expand_path(from) unless descriptor.original_location_path
        descriptor.location = File.basename(to)
        descriptor.location_path = to
        to_archive.update_index(:descriptor=>descriptor)
      end
    end
    private :cp_file_to_file
    
    def mv(options={})
      from = options[:from]
      from_path = expand_path(from)
      to = options[:to]
      to_path = expand_path(to)
      if File.directory?(from_path)
        cp(options.merge(:from=>from, :to=>to_path, :recursive=>true))
        rm_at_path(from_path, :recursive=>true)
      else
        cp(options.merge(:from=>from, :to=>to_path))
        rm_at_path(from_path)
      end
    end
    
    def mkdir(path, options={})
      path = expand_path(path)
      if options[:p] || options[:parents]
        FileUtils.mkdir_p(path)
      else
        FileUtils.mkdir(path)
      end
    end
  end
end