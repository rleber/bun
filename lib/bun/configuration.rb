#!/usr/bin/env ruby
#  -*- encoding: utf-8 -*-

# Class to define config file

require 'yaml'

module Bun
  class Configuration
    include CacheableMethods
    
    PROJECT_DIRECTORY = File.join(File.dirname(__FILE__), '..', '..') # Two levels up from the directory this file is in
    DATA_DIRECTORY = File.join(PROJECT_DIRECTORY, 'data')
    CONFIG_INIT_PATH = File.join(DATA_DIRECTORY,'bun_config_init.yml')
    CONFIG_DEFINITIONS_PATH = File.join(DATA_DIRECTORY,'config_keys.yml')

    class << self
    
      CONFIG_FILE_NAME = '.bun_config.yml'
      DEFAULT_CONFIG_PATH = File.join(ENV['HOME'], CONFIG_FILE_NAME)
 
      def location
        @location ||= default_location
      end
      
      def default_location
        ENV['BUN_CONFIG'] || DEFAULT_CONFIG_PATH
      end
      
      def location=(path)
        @location = path
      end
      
      def definitions
        content = ::Bun.readfile(CONFIG_DEFINITIONS_PATH, :encoding=>'us-ascii')
        YAML.load(content)
      end
      
      def default_keys
        definitions.keys
      end
    end
    
    def initialize
      @setting = read
    end
    
    def init
      @setting = File.exists?(location) ? read : init
    end
    
    def init
      setting = _read(CONFIG_INIT_PATH)
      write(setting)
      setting
    end
    
    def location
      self.class.location
    end
    
    def places
      setting[:places] || {}
    end
    
    def places=(p)
      setting[:places] = p
    end
    
    def keys
      @setting.keys
    end
    
    def all_keys
      (keys + self.class.default_keys).uniq
    end
    
    def location=(locn)
      @location = locn
    end
    
    attr_writer :setting
    
    def _read(location)
      location ||= self.location
      begin
        content = ::Bun.readfile(location, :encoding=>'us-ascii')
        content ? YAML.load(content) : {}
      rescue => e
        stop "!Unable to read configuration file at #{location}: #{e}"
      end
    end
    
    def read
      @setting = _read(location)
    end
    
    def setting
      @setting ||= read
    end
    
    def expanded_setting(name)
      ::File.expand_path(setting[name.to_s])
    end
    
    def write(setting=nil)
      setting ||= @setting
      ::File.open(location, 'w') do |f|
        f.write(YAML.dump(setting))
      end
    end
  end
end