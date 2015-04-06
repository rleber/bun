#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

module Bun
  DEFAULT_PACKED_FILE_EXTENSION = ''
  DEFAULT_UNPACKED_FILE_EXTENSION = '.bun'
  DEFAULT_CATALOGED_FILE_EXTENSION = '.bun'
  DEFAULT_DECODED_FILE_EXTENSION = ''
  DEFAULT_BAKED_FILE_EXTENSION = ''
  UNDECODABLE_EXTENSION = ''
  DEFAULT_BAKED_INDEX_DIRECTORY = '.INDEX'
  INDEX_FILE_EXTENSION = '.yaml'

  class << self

    def readfile(file, options={})
      encoding = options[:encoding] || 'ascii-8bit'
      return $stdin.read.force_encoding(encoding) if file == '-'
      return nil unless ::File.file?(file)
      ::File.read(file).force_encoding(encoding)
    end
    
    def convert_glob(pat)
      Regexp.new(%{^#{pat.gsub('.', "\\.").gsub('*','.*')}$})
    end
    
    def expanded_version
      "Bun version #{version} [#{git_branch}:#{git_hash}]"
    end
    
    def version
      Bun::VERSION
    end
    
    def git_hash
      `git rev-parse HEAD`.chomp
    end
    
    def git_branch
      `git branch | grep '*'`[/\*\s+(.*)/,1]
    end
    
    def project_relative_path(path)
      path.sub(%r{^.*bun/}, '')
    end

    def project_path(path)
      path = File.expand_path(path)
      if path =~ %r{^(.*?bun)/}
        $1
      else
        nil
      end
    end

    @@cache = {}
    def cache(cache, args, value=nil, &blk)
      cache_at(cache, args) || (@@cache[cache] = [args, (block_given? ? yield : value)]).last.dup
    end

    def cache_at(cache, args)
      cache_entry = @@cache[cache]
      cache_entry && (cache_entry.first == args) && cache_entry.last.dup
    end

    # def cache_at(name)
    #   @@cache[name]
    # end

    # def cache_clear(name)
    #   @@cache.delete(name)
    # end

    # def cache_force(name, value=nil, &blk)
    #   cache_clear(name)
    #   cache(name,value, &blk)
    # end
  end
end

require 'rubygems'
require 'date'
require 'lib/kernel'
require 'lib/hash'
require 'lib/cacheable_methods'
require 'lib/bun/date'
require 'lib/bun/roff'
require 'lib/bun/version'
require 'lib/bun/bots'