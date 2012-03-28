#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

module Bun
  def self.readfile(file, options={})
    return nil unless File.file?(file)
    encoding = options[:encoding] || 'ascii-8bit'
    ::File.read(file, :encoding=>encoding)
  end
  
  def self.convert_glob(pat)
    Regexp.new(%{^#{pat.gsub('.', "\\.").gsub('*','.*')}$})
  end
end

require 'rubygems'
require 'date'
require 'lib/kernel'
require 'lib/cacheable_methods'
require 'lib/bun/date'
require 'lib/bun/bots'