#!/usr/bin/env rvm-ruby 1.9.3
# -*- encoding: us-ascii -*-

require 'lib/bun/collection'
require 'lib/bun/catalog'
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
            contents << "#{tape}[#{file.shard_name(i)}]"
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
        
    def unpack(glob, to, options={})
      to_path = expand_path(to, :from_wd=>true) # @/foo form is allowed
      FileUtils.rm_rf to_path unless options[:dryrun]
      Dir.glob(expand_path(glob)).each do |tape|
        from_tape = relative_path(tape, :relative_to=>File.expand_path(at))
        to_file  = File.join(to_path, from_tape)        
        warn "unpack #{from_tape} => #{to_file}" if options[:dryrun] || !options[:quiet]
        unless options[:dryrun]
          dir = File.dirname(to_file)
          FileUtils.mkdir_p dir
          File.unpack(expand_path(from_tape), to_file) unless options[:dryrun]
        end
      end
      to_archive = self.class.new(to_path)
      to_archive.set_timestamps(:quiet=>true)
    end

    # TODO Add glob capability?
    def decode(to, options={})
      to_path = expand_path(to, :from_wd=>true) # @/foo form is allowed
      FileUtils.rm_rf to_path unless options[:dryrun]
      tapes.each do |tape|
        file = open(tape)
        case file.file_type
        when :frozen
          file.shard_count.times do |i|
            descr = file.shard_descriptor(i)
            shard_name = descr.name
            warn "unpack #{tape}[#{shard_name}]" if options[:dryrun] || !options[:quiet]
            unless options[:dryrun]
              timestamp = file.descriptor.timestamp
              f = File.join(to_path, decode_path(file.path, timestamp), shard_name, decode_tapename(tape, descr.file_time))
              dir = File.dirname(f)
              FileUtils.mkdir_p dir
              file.decode f, :shard=>shard_name
            end
          end
        when :text
          warn "unpack #{tape}" if options[:dryrun] || !options[:quiet]
          unless options[:dryrun]
            timestamp = file.descriptor.timestamp
            f = File.join(to_path, file.path, decode_tapename(tape, timestamp))
            dir = File.dirname(f)
            FileUtils.mkdir_p dir
            file.decode f
          end
        else
          warn "skipping #{tape}: unknown type (#{file.file_type})" if options[:dryrun] || !options[:quiet]
        end
      end
    end
    
    EXTRACT_DATE_FORMAT = "%Y%m%d_%H%M%S"
    EXTRACT_TAPE_PREFIX = 'tape.'
    EXTRACT_TAPE_SUFFIX = '.txt'

    def decode_path(path, date)
      if date
        date_to_s = date.strftime(EXTRACT_DATE_FORMAT)
        date_to_s = $1 if date_to_s =~ /^(.*)_000000$/
        path + '_' + date_to_s
      else
        path
      end
    end

    def decode_tapename(path, date)
      EXTRACT_TAPE_PREFIX + decode_path(path, date) + EXTRACT_TAPE_SUFFIX
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