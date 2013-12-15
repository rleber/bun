#!/usr/bin/env ruby
#  -*- encoding: utf-8 -*-

# Set a configuration

desc "set KEY VALUE", "Set configuration setting"
def set(key,value)
  config = Configuration.new
  config.read
  config.setting[key] = value
  config.write
end