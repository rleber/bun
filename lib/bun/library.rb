#!/usr/bin/env rvm-ruby 1.9.3
# -*- encoding: us-ascii -*-

require 'lib/bun/collection'
require 'lib/bun/file'
require 'date'

module Bun
  class Library < Collection
    
    def initialize(*args)
      super
      @recursive_index = true
    end
    
    def files(&blk)
      contents(&blk)
    end
    
    def contents(&blk)
      glob('**/*', &blk)
    end
    
    def compact!
      compact_leaves!
    end
    
    def compact_leaves!
      leaves.chunk {|leaf| leaf =~ /^(.*)\.(\d{8}(?:_\d{6})?)(?:\.txt)?$/ && $1 } \
            .reject{|set, leaves| set.nil?} \
            .each do |set, leaves|
              leaves.map {|leaf| [leaf, (fd=descriptor(leaf)) && fd.updated]} \
                    .reject {|leaf, updated| updated.nil?} \
                    .map {|leaf, updated| [leaf, updated, File.read(expand_path(leaf))]} \
                    .inject([]) do |redundant_set, leaf_info|
                      newer_leaf, newer_updated, newer_content = leaf_info
                      redundant = false
                      redundant_set.each do |older_candidate|
                        older_leaf, older_updated, older_content = older_candidate
                        redundant_set << leaf_info if older_content == newer_content
                      end
                    end \
                    .each do |redundant_leaf, *|
                      rm redundant_leaf
                    end
            end
    end
    
    def bake(to, options={})
      to_path = expand_path(to, :from_wd=>true) # @/foo form is allowed
      FileUtils.rm_rf to_path if options[:force] && !options[:dryrun]
      leaves.each do |leaf|
        # file = File::Decoded.open(leaf)
        relative_leaf = relative_path(leaf)
        if options[:dryrun]
          warn "bake #{relative_leaf}" unless options[:quiet]
        else
          to_file = File.join(to_path,relative_leaf)
          if !options[:force] && (conflicting_part=File.conflicts?(to_file))
            conflicting_part.sub!(/^#{Regexp.escape(to_path)}\//,'')
            conflicting_part = 'it' if conflicting_part == relative_leaf
            warn "skipping bake #{relative_leaf}; #{conflicting_part} already exists" unless options[:quiet]
            next
          end
          success = begin
            File.bake(leaf, to_file, promote: true, scrub: options[:scrub])
            warn "bake #{relative_leaf}" unless options[:quiet]
            true
          rescue File::CantDecodeError
            warn "unable to bake #{relative_leaf}" unless options[:quiet]
            false
            # Skip the file
          end
          if success
            unless options[:now]
              timestamp = File.timestamp(leaf)
              set_timestamp(to_file, timestamp)
            end
          end
        end
      end
    end

    def scrub(to, options={})
      to_path = expand_path(to, :from_wd=>true) # @/foo form is allowed
      FileUtils.rm_rf to_path unless options[:dryrun]
      leaves.each do |leaf|
        # file = File::Decoded.open(leaf)
        relative_leaf = relative_path(leaf)
        to_file = File.join(to_path,relative_leaf)
        File.scrub(leaf, to_file, options)
        $stderr.puts "scrub #{relative_leaf}" unless options[:quiet]
      end
    end
    
    def classify(to, options={})
      no_move = options[:dryrun] || !to
      shell = Shell.new(:dryrun=>no_move)
      shell.rm_rf(to) if to && File.exists?(to)
      command = options[:copy] ? :cp : :ln_s
      test = options[:test] || 'clean'

      leaves.each do |old_file|
        f = relative_path(old_file)
        status = Bun::File::Decoded.trait(old_file, test).to_s
        warn "#{f} is #{status}" unless options[:quiet]
        unless no_move
          new_file = File.join(to, status, f)
          shell.mkdir_p File.dirname(new_file)
          shell.invoke command, old_file, new_file
        end
      end
    end
  end
end