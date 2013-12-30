#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

module Bun
  DEFAULT_PACKED_FILE_EXTENSION = ''
  DEFAULT_UNPACKED_FILE_EXTENSION = '.bun'
  
  def self.readfile(file, options={})
    encoding = options[:encoding] || 'ascii-8bit'
    return $stdin.read.force_encoding(encoding) if file == '-'
    return nil unless ::File.file?(file)
    Bun::File.read(file, :encoding=>encoding)
  end
  
  def self.convert_glob(pat)
    Regexp.new(%{^#{pat.gsub('.', "\\.").gsub('*','.*')}$})
  end
  
  def self.expanded_version
    "Bun version #{version} [#{git_branch}:#{git_hash}]"
  end
  
  def self.version
    Bun::VERSION
  end
  
  def self.git_hash
    `git rev-parse HEAD`.chomp
  end
  
  def self.git_branch
    `git branch | grep '*'`[/\*\s+(.*)/,1]
  end
end

require 'rubygems'
require 'date'
require 'lib/kernel'
require 'lib/cacheable_methods'
require 'lib/bun/date'
require 'lib/bun/version'
require 'lib/bun/bots'