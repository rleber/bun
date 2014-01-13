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
      leaves.chunk {|leaf| leaf =~ /^(.*)\.(\d{8}(?:_\d{6})?)\.txt$/ && "#{$1}.txt" } \
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
      FileUtils.rm_rf to_path unless options[:dryrun]
      leaves.each do |leaf|
        # file = File::Decoded.open(leaf)
        relative_leaf = relative_path(leaf)
        if options[:dryrun]
          $stderr.puts "bake #{relative_leaf}" unless options[:quiet]
        else
          to_file = File.join(to,relative_leaf)
          begin
            File.bake(leaf, to_file, promote: true)
            $stderr.puts "bake #{relative_leaf}" unless options[:quiet]
          rescue File::CantDecodeError
            $stderr.puts "unable to bake #{relative_leaf}" unless options[:quiet]
            # Skip the file
          end
          # if File.file_grade(leaf) == :baked
          #   shell = Shell.new
          #   shell.mkdir_p File.dirname(to_file)
          #   shell.cp leaf, to_file
          # else
          #   file = File::Decoded.open(leaf, promote: true)
          #   file.bake(to_file)
          # end
        end
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
        status = Bun::File::Decoded.examination(old_file, test).to_s
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