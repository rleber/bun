#!/usr/bin/env ruby
#  -*- encoding: utf-8 -*-

# Remove a configuration

desc "rm KEY", "Remove place name"
def rm(key)
  config = Configuration.new
  config.places.delete(key)
  config.write
end