#!/usr/bin/env ruby
#  -*- encoding: utf-8 -*-

# Remove a configuration

desc "rm KEY VALUE", "Remove configuration setting"
def rm(key)
  config = Configuration.new
  config.read
  config.setting.delete(key)
  config.write
end