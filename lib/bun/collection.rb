#!/usr/bin/env rvm-ruby 1.9.3
# -*- encoding: us-ascii -*-

require 'yaml'
require 'hashie/mash'
require 'lib/bun/file'
require 'lib/bun/collection_enumerator'
require 'lib/bun/configuration'

module Bun
  class Collection
    include Enumerable
    include CacheableMethods
    
    class NonRecursiveRemoveDirectory < ArgumentError; end
    class CopyDirectoryNonRecursive < ArgumentError; end
    class CopyMissingFromFile < ArgumentError; end
    class CopyToNonDirectory < ArgumentError; end
    
    attr_reader :at
    
    class << self
      def enumerator_class
        Enumerator
      end
    end
    
    def initialize(options={})
      @at = File.expand_path(options[:at] || default_at)
      @index = nil
      @update_indexes = options.has_key?(:update_indexes) ? options[:update_indexes] : true
    end
    
    def hoards
      Dir.entries(at).reject{|f| f=~/^\./}
    end

    def open(name, options={}, &blk)
      if File.basename(name) =~ /^ar\d{3}.\d{4}$/
        Bun::File::Archived.open(expand_path(name), options.merge(:archive=>self, :hoard=>name), &blk)
      else
        Bun::File::Extracted.open(expand_path(name), options.merge(:library=>self,  :hoard=>name), &blk)
      end
    end

    def to_enum(&blk)
      self.class.enumerator_class.new(self, &blk)
    end
    
    def each(&blk)
      to_enum.each(&blk)
    end
    
    def all(&blk)
      to_enum.all(&blk)
    end
    
    def directories(&blk)
      to_enum.directories(&blk)
    end
    
    alias_method :folders, :directories
    
    def leaves(&blk)
      to_enum.leaves(&blk)
    end
    
    alias_method :items, :leaves
    alias_method :fragments, :leaves
    
    def each_file(options={}, &blk)
      to_enum.files(options, &blk)
    end
    
    def glob(*pat, &blk)
      to_enum.glob(*pat, &blk)
    end
    
    def depth
      first = all.depth_first.with_depth.next
      return 0 unless first
      name, depth = first
      depth
    end
    
    def default_at
      File.expand_path(default_config.setting['at_path'])
    end

    def config_dir(name)
      dir = config.setting[name.to_s]
      return nil unless dir
      dir = File.expand_path(dir) if dir=~/^(~|\.)\//
      dir
    end
    
    def default_config_file
      File.expand_path(File.join(File.dirname(__FILE__), '..','..','data','archive_config.yml'))
    end
    
    def read_config_file(config_file)
      @config = Configuration.new(:hoard=>config_file)
      @config.read
    end
    
    def default_config
      @default_config = Configuration.new(:hoard=>default_config_file)
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
      expand_path(config.setting[name.to_s])
    end
    
    def index_directory
      config.setting['index_directory']
    end
    
    def index_directories
      Dir.glob(at + '/**/' + index_directory)
    end
    
    def index_prefix(ix=nil)
      ix ||= expanded_index_directory
      res = File.dirname(ix)
      res = '' if res == '.'
      res
    end
    
    def index_path(name, ix=nil)
      ix ? File.join(ix, name) : expand_path(name)
    end
    
    def index_for(name, ix=nil)
      expanded_path = index_path(name)
      index[expanded_path]
    end
    
    def expanded_index_directory
      expanded_config('index_directory')
    end
    
    def expand_path(hoard, options={})
      if options[:from_wd] # Expand relative to working directory
        case hoard
        when /^@\/(.*)/ # syntax @/xxxx means expand relative to archive
               return expand_path($1)
        when /^\\(@.*)/ # syntax \@xxxx means ignore the '@'; expand relative to working directory
          hoard = $1
        end
        rel = `pwd`.chomp
      else # expand relative to archive
        rel = File.expand_path(at)
      end
      File.expand_path(hoard, rel)
    end
    
    def relative_path(*f)
      File.relative_path(*f, :relative_to=>at)
    end
    
    def index(options={})
      return @index if !options[:build] && @index
      res = _index(options)
      @index = res unless options[:no_save]
      res
    end
    
    def _index(options={})
      if options[:recursive]
        indexes = index_directories
      else
        indexes = [expanded_index_directory]
      end
      if indexes.size > 0
        res = {}
        indexes.each do |index|
          raise RuntimeError, "File #{index} should be a directory" unless File.directory?(index)
          prefix = index_prefix(index)
          Dir.glob(File.join(index, '*.yml')) do |f|
            raise "Unexpected file #{f} in index #{expanded_index_directory}" unless f =~ /\.descriptor.yml$/
            file_name = index_path(File.basename($`), prefix)
            content = ::Bun.readfile(f, :encoding=>'us-ascii')
            res[file_name] = YAML.load(content)
          end
        end
        res
      else
        build_and_save_index
      end
    end
    private :_index
    
    def build_and_save_index(options={})
      clear_index
      items.with_files(:header=>true) do |fname, f|
        puts f.hoard if options[:verbose]
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
      clear_index_directories
      @index = nil
    end
    
    # TODO Allow for indexing by other than hoard?
    def update_index(options={})
      @index ||= {}
      descr = options[:descriptor] ? options[:descriptor].to_hash : build_descriptor_for_file(options[:file])
      descr.keys.each do |k|
        if k.is_a?(String)
          descr[k.to_sym] = descr[k]
          descr.delete(k)
        end
      end
      @index[descr[:hoard]] = descr
      save_index_descriptor(descr[:hoard])
      descr
    end
    
    def build_descriptor(name)
      open(name, :header=>true) {|f| build_descriptor_for_file(f) }
    end
    
    def build_descriptor_for_file(f)
      entry = f.descriptor.to_hash
      entry
    end
    
    def clear_index_directories
      return unless @update_indexes
      index_directories.each do |index_directory|
        FileUtils.rm_rf(index_directory)
      end
    end
    
    def save_index
      clear_index_directories
      items do |name|
        _save_index_descriptor(name)
      end
      @index
    end
    
    def save_index_descriptor_for_file(f)
      @index ||= {}
      name = f.hoard
      @index[name] ||= build_descriptor_for_file(f)
      _save_index_descriptor(name)
    end
    
    def save_index_descriptor(name)
      @index ||= {}
      @index[name] ||= build_descriptor(name)
      make_index_directory
      _save_index_descriptor(name)
    end
    
    def make_index_directory
      FileUtils.mkdir_p(expanded_index_directory) unless File.exists?(expanded_index_directory)
    end
    
    def _save_index_descriptor(name)
      return unless @update_indexes
      descriptor_file_parts = [at]
      descriptor_directory = File.dirname(name)
      descriptor_file_parts << descriptor_directory unless descriptor_directory == '.'
      descriptor_file_parts << index_directory
      descriptor_file_parts << File.basename(name) + '.descriptor.yml'
      descriptor_file_name = File.join(*descriptor_file_parts)
      # TODO This trap code was inserted to catch a tricky little bug; I'm leaving it here for awhile
      # if name == 'ar145.2699' && @index[name][:updated].nil?
      #   puts "_save_index_descriptor(#{name.inspect}): index=#{@index[name].inspect}"
      #   raise RuntimeError, ":updated == nil"
      # end
      FileUtils.mkdir_p File.dirname(descriptor_file_name)
      ::File.open(descriptor_file_name, 'w:us-ascii') {|f| f.write @index[name].to_yaml }
    end
    private :_save_index_descriptor
    
    # Options:
    #  :build: true  Always build descriptor from file data, never use index
    #          false Use index if available, never build from file data
    #          nil   Use index if available, otherwise build from file data
    def descriptor(name, options={})
#      i = index        # TODO Remove this if everything is still working; not sure what its purpose was
      if !exists?(name)
        nil
      elsif !options[:build] && index_for(name)
        Hashie::Mash.new(index_for(name))
      elsif options[:build] == false # False signifies "Do not ever build from file data, even if no index"
        nil
      else
        Hashie::Mash.new(build_descriptor(name))
      end
    end
    
    def exists?(name)
      File.exists?(expand_path(name))
    end
    
    def rm(options={})
      glob(*options[:hoards]) do |fname|
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
        descriptor_file_name = File.join(File.dirname(path), index_directory, "#{File.basename(path)}.descriptor.yml")
#        puts "In Archive#rm_at_path: path=#{path.inspect}, descriptor_file_name=#{descriptor_file_name.inspect}"
        FileUtils.rm(descriptor_file_name) if File.exists?(descriptor_file_name)
      end
    end
    private :rm_at_path
    
    def erase!
      FileUtils.rm_rf(at)
    end
    
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
      from = '*' if from == '.'
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
            if File.directory?(from_item)
              new_directory = File.join(target_dir,File.basename(from_item))
              if File.exists?(new_directory)
                raise CopyToNonDirectory "Can't copy directory #{from_item } to non-directory #{new_directory}" \
                  unless File.directory?(new_directory)
              else
                FileUtils.mkdir(new_directory)
              end
            else
              cp_single_file(options.merge(:from=>from_item, :to=>target_dir + '/'))
            end
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
    
    # Copy a single file to a file hoard. If the file already exists, it
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
        f.copy_descriptor(to) if index
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