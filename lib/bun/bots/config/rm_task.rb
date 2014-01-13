#!/usr/bin/env ruby
#  -*- encoding: utf-8 -*-

# Remove a configuration

desc "rm KEY", "Remove configuration setting"
def rm(key)
  check_for_unknown_options(key)
  config = Configuration.new
  config.setting.delete(key.to_sym)
  config.write
end