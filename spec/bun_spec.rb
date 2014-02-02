#!/usr/bin/env rvm-ruby 1.9.3
# -*- encoding: us-ascii -*-

require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

Dir.glob(::File.join(::File.dirname(__FILE__),'bun/*_spec.rb')).each do |test_file|
  require test_file
end
