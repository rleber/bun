#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

target = File.dirname(File.dirname(__FILE__))
$:.unshift(target) unless $:.include?(target) || $:.include?(File.expand_path(target))

require 'lib/bun/base'