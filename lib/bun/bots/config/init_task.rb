#!/usr/bin/env ruby
#  -*- encoding: utf-8 -*-

# Initialize the configuration

desc "init", "Initialize bun configuration"
def init
  config = Configuration.new
  config.init
end