#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

module Bun
  def self.readfile(file, options={})
    if RUBY_VERSION =~ /^1\.8/
      ::File.read(file)
    else
      encoding = options[:encoding] || 'ascii-8bit'
      ::File.read(file, :encoding=>encoding)
    end
  end
end

require 'rubygems'
require 'date'
require 'lib/kernel'
require 'lib/cacheable_methods'
require 'lib/date'
require 'lib/bun/bots'