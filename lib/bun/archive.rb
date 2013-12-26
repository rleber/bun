#!/usr/bin/env rvm-ruby 1.9.3
# -*- encoding: us-ascii -*-

require 'lib/bun/collection'
require 'lib/bun/file'
require 'date'

module Bun
  class Archive < Collection
    
    class << self
      def enumerator_class
        Archive::Enumerator
      end
    end
    
    # TODO Is there a more descriptive name for this?
    def contents(&blk)
      tapes = self.tapes
      contents = []
      each do |tape|
        file = open(tape)
        if file.file_type == :frozen
          file.shard_count.times do |i|
            contents << "#{tape}[#{file.shards[i][:name]}]"
          end
        else
          contents << tape
        end
      end
      if block_given?
        contents.each(&blk)
      end
      contents
    end

    def catalog_path
      # TODO Remove this direct reference
      cp = config.places['catalog']
      cp && ::File.expand_path(cp)
    end
    
    def catalog
      cp = catalog_path
      content = cp && Bun.readfile(catalog_path, :encoding=>'us-ascii')
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
        {:tape=>words[0], :date=>date, :file=>words[2]}
      end
      specs
    end
    cache :catalog
    
    def catalog_time(tape)
      info = catalog.find {|spec| spec[:tape] == tape }
      info && info[:date].local_date_to_local_time
    end
    
    def convert(glob, to, options={})
      to_path = expand_path(to, :from_wd=>true) # @/foo form is allowed
      FileUtils.rm_rf to_path unless options[:dryrun]
      Dir.glob(expand_path(glob)).each do |tape|
        from_tape = relative_path(tape, :relative_to=>File.expand_path(at))
        to_file  = File.join(to_path, from_tape)        
        warn "convert #{from_tape} => #{to_file}" if options[:dryrun] || !options[:quiet]
        unless options[:dryrun]
          dir = File.dirname(to_file)
          FileUtils.mkdir_p dir
          convert_single(from_tape, to_file) unless options[:dryrun]
        end
      end
    end
    
    # Convert a file from internal bun binary format to YAML digest
    def convert_single(tape,to=nil)
      content = open(tape) {|f| f.convert}
      shell = Shell.new
      shell.write to, content
    end

    # TODO Add glob capability?
    def extract(to, options={})
      to_path = expand_path(to, :from_wd=>true) # @/foo form is allowed
      FileUtils.rm_rf to_path unless options[:dryrun]
      tapes.each do |tape|
        file = open(tape)
        case file.file_type
        when :frozen
          file.shard_count.times do |i|
            descr = file.shard_descriptor(i)
            shard_name = descr.name
            warn "thaw #{tape}[#{shard_name}]" if options[:dryrun] || !options[:quiet]
            unless options[:dryrun]
              f = File.join(to_path, extract_path(file.path, file.updated), shard_name, extract_tapename(tape, descr.updated))
              dir = File.dirname(f)
              FileUtils.mkdir_p dir
              file.extract shard_name, f
            end
          end
        when :text
          warn "unpack #{tape}" if options[:dryrun] || !options[:quiet]
          unless options[:dryrun]
            f = File.join(to_path, file.path, extract_tapename(tape, file.updated))
            dir = File.dirname(f)
            FileUtils.mkdir_p dir
            file.extract f
          end
        else
          warn "skipping #{tape}: unknown type (#{file.file_type})" if options[:dryrun] || !options[:quiet]
        end
      end
    end
    
    EXTRACT_DATE_FORMAT = "%Y%m%d_%H%M%S"
    EXTRACT_TAPE_PREFIX = 'tape.'
    EXTRACT_TAPE_SUFFIX = '.txt'

    def extract_path(path, date)
      return path unless date
      date_to_s = date.strftime(EXTRACT_DATE_FORMAT)
      date_to_s = $1 if date_to_s =~ /^(.*)_000000$/
      res = path + '_' + date_to_s
      res
    end

    def extract_tapename(path, date)
      EXTRACT_TAPE_PREFIX + extract_path(path, date) + EXTRACT_TAPE_SUFFIX
    end
    
    def items(&blk)
      to_enum.items(&blk)
    end
    
    def fragments(&blk)
      to_enum.fragments(&blk)
    end
    
    def folders(&blk)
      to_enum.folders(&blk)
    end
  end
end