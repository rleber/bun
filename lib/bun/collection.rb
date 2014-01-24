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
    
    def initialize(at, options={})
      @at = at
      @index = nil
      @update_indexes = options.has_key?(:update_indexes) ? options[:update_indexes] : true
    end
    
    def tapes
      Dir.entries(at).reject{|f| f=~/^\./}
    end

    def open(name, options={}, &blk)
      path = expand_path(name)
      File.open(path, options.merge(:archive=>self, :tape=>name), &blk)
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
    
    def leaves(options={}, &blk)
      to_enum.leaves(options, &blk)
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
      @config = Configuration.new(:tape=>config_file)
      @config.read
    end
    
    def default_config
      @default_config = Configuration.new
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
      setting = config.setting[name]
      setting && expand_path(setting)
    end
    
    def index_directory
      config.setting[:index_directory]
    end
    
    def index_directories
      Dir.glob(at + '/**/' + index_directory)
    end
    
    def index_prefix(ix=nil)
      ix ||= expanded_index_directory
      res = File.expand_path(File.dirname(ix))
      res = '' if res == '.'
      res
    end
    
    def index_path(name, ix=nil)
      ix ? File.join(ix, name) : expand_path(name)
    end
    
    def index_for(name)
      index[expand_path(name)]
    end
    
    def expanded_index_directory
      expanded_config(:index_directory)
    end
    
    def expand_path(tape, options={})
      if options[:from_wd] # Expand relative to working directory
        case tape
        when /^@\/(.*)/ # syntax @/xxxx means expand relative to archive
               return expand_path($1)
        when /^\\(@.*)/ # syntax \@xxxx means ignore the '@'; expand relative to working directory
          tape = $1
        end
        rel = `pwd`.chomp
      elsif !options[:already_from_wd] # expand relative to archive
        rel = File.expand_path(at)
      end
      File.expand_path(tape, rel)
    end
    
    def relative_path(*f)
      options = {}
      if f.last.is_a?(Hash)
        options = f.pop
      end
      unless options[:relative_to]
        base = File.directory?(at) ? at : File.dirname(at)
        options.merge!(:relative_to=>File.expand_path(base)) 
      end
      File.relative_path(*f, options)
    end
    
    def index
      @index ||= build_index
    end
    
    def build_index
      items.inject({}) do |index_hash, item|
        descriptor = File.descriptor(item)
        index_hash[expand_path(item, :already_from_wd=>true)] = descriptor if descriptor
        index_hash
      end
    end
    private :build_index
    
    def build_and_save_index(options={})
      clear_index
      items.with_files(:header=>true, :already_from_wd=>true) do |fname, f|
        puts f.tape if options[:verbose]
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
    
    # TODO Allow for indexing by other than tape?
    def update_index(options={})
      @index ||= {}
      descr = options[:descriptor] ? options[:descriptor].to_hash : build_descriptor_for_file(options[:file])
      descr.keys.each do |k|
        if k.is_a?(String)
          descr[k.to_sym] = descr[k]
          descr.delete(k)
        end
      end
      @index[descr[:tape]] = descr
      save_index_descriptor(descr[:tape])
      descr
    end
    
    def set_timestamps(options={})
      shell = Bun::Shell.new(options)
      each do |tape|
        if descr = descriptor(tape)
          timestamp = [descr[:catalog_time], descr[:time]].compact.min
          if timestamp
            warn "Set timestamp: #{tape} #{timestamp.strftime('%Y/%m/%d %H:%M:%S')}" unless options[:quiet]
            set_timestamp(tape, timestamp, :shell=>shell) unless options[:dryrun]
          else
            warn "No timestamp available for #{tape}" unless options[:quiet]
          end
        end
      end
    end
    
    def set_timestamp(tape, timestamp, options={})
      if timestamp
        shell = options[:shell] || Bun::Shell.new(options)
        shell.set_timestamp(expand_path(tape), timestamp)
      end
    end

    def apply_catalog(catalog_path, options={})
      shell = Bun::Shell.new(options)
      cat = catalog(catalog_path)
      leaves do |tape_path|
        tape = relative_path(tape_path, from_wd: true)
        case File.format(tape_path)
        when :packed
          # TODO Refactor using built-in file promotion capability
          new_tape_path = tape_path.sub(/#{DEFAULT_PACKED_FILE_EXTENSION}$/,'') + DEFAULT_UNPACKED_FILE_EXTENSION
          File.unpack(tape_path, new_tape_path)
          Shell.new.rm_rf tape_path
          tape_path = new_tape_path
          tape = relative_path(tape_path, from_wd: true)
        when :unpacked
          # Do nothing; file is already unpacked
        else
          next
        end
        cat_entry = cat[tape]
        if cat_entry
          warn "Set catalog time: #{tape} #{cat_entry.time.strftime('%Y/%m/%d %H:%M:%S')}" unless options[:quiet]
          set_catalog_time(tape, cat_entry, :shell=>shell) unless options[:dryrun]
        elsif options[:remove]
          warn "Remove #{tape} (not in catalog)" unless options[:quiet]
          remove(tape) unless options[:dryrun]
        else
          warn "Skipping #{tape}: not in catalog" unless options[:quiet]
        end
      end
    end
    
    def set_catalog_time(tape, catalog_entry, options={})
      file = open(tape)
      file = file.unpack
      descr = file.descriptor
      descr.merge!(:catalog_time=>catalog_entry.time)
      descr.merge!(:incomplete_file=>true) if catalog_entry.incomplete
      file.write
      timestamp = [descr.catalog_time, descr.time].compact.min
      set_timestamp(tape, timestamp, :shell=>options[:shell])
    end
    
    def catalog(cp)
      unless @catalog && @catalog.at == ::File.expand_path(cp)
        @catalog = Catalog.new(cp)
      end
      @catalog
    end
    
    def catalog_time(tape)
      info = catalog.find {|spec| spec[:tape] == tape }
      info && info[:date].local_date_to_local_time
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
      name = f.tape
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
    
    def descriptor(name)
      exists?(name) && index_for(name)
    end
    
    def exists?(name)
      File.exists?(expand_path(name))
    end
    
    def rm(options={})
      glob(*options[:tapes]) do |fname|
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
      cp_file_to_file(:from=>from, :to=>to)
    end
    private :cp_single_file
    
    # Copy a single file to a file tape. If the file already exists, it
    # is overwritten. 
    def cp_file_to_file(options={})
      from = options[:from]
      to = options[:to]
      to_stdout = to.nil? || to == '-'
      index = !to_stdout
      unless to_stdout
        to = '.' if to == ''
        to = File.join(to, File.basename(from)) if File.directory?(to)
      end
      
      open(from) do |f|
        Shell.new(:quiet=>true).write to, f.read, :mode=>'w:ascii-8bit'
        # f.copy_descriptor(to) if index
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