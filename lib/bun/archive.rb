#!/usr/bin/env rvm-ruby 1.9.3
# -*- encoding: us-ascii -*-

require 'lib/bun/collection'
require 'lib/bun/file'
require 'date'

module Bun
  class Archive < Collection
    
    def tapes
      locations
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

    def catalog_file
      expanded_config(:catalog_file)
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
    
    def open(name, options={}, &blk)
      Bun::File::Archived.open(expand_path(name), options.merge(:archive=>self, :location=>name), &blk)
    end

    def extract(to, options={})
      to_path = expand_path(to, :from_wd=>true) # @/foo form is allowed
      FileUtils.rm_rf to_path unless options[:dryrun]
      locations.each do |location|
        file = open(location)
        case file.file_type
        when :frozen
          file.shard_count.times do |i|
            descr = file.shard_descriptor(i)
            shard_name = descr.name
            warn "thaw #{location}[#{shard_name}]" if options[:dryrun] || !options[:quiet]
            unless options[:dryrun]
              f = File.join(to_path, extract_path(file.path, file.updated), shard_name, extract_filename(location, descr.updated))
              dir = File.dirname(f)
              FileUtils.mkdir_p dir
              file.extract shard_name, f
            end
          end
        when :text
          warn "unpack #{location}" if options[:dryrun] || !options[:quiet]
          unless options[:dryrun]
            f = File.join(to_path, file.path, extract_filename(location, file.updated))
            dir = File.dirname(f)
            FileUtils.mkdir_p dir
            file.extract f
          end
        else
          warn "skipping #{location}: unknown type (#{file.file_type})" if options[:dryrun] || !options[:quiet]
        end
      end
    end
    
    EXTRACT_DATE_FORMAT = "%Y%m%d_%H%M%S"
    EXTRACT_SUFFIX = '.txt'

    def extract_path(path, date)
      return path unless date
      date_to_s = date.strftime(EXTRACT_DATE_FORMAT)
      date_to_s = $1 if date_to_s =~ /^(.*)_000000$/
      path + '_' + date_to_s
    end

    def extract_filename(path, date)
      extract_path(path, date) + EXTRACT_SUFFIX
    end
  end
end