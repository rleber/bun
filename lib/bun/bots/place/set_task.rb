#!/usr/bin/env ruby
#  -*- encoding: utf-8 -*-

# Define a place

desc "set KEY VALUE", "Define a place"
def set(key,value)
  check_for_unknown_options(key, value)
  config = Configuration.new
  config.places[key] = value
  config.write
end