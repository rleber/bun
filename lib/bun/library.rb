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
        $stderr.puts "put #{relative_leaf}" unless options[:quiet]
        unless options[:dryrun]
          to_file = File.join(to,relative_leaf)
          file = File::Decoded.open(leaf)
          file.bake(to_file)
        end
      end
    end
    
  end
end