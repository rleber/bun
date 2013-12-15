#!/usr/bin/env ruby
#  -*- encoding: utf-8 -*-

# Class to define config file

require 'yaml'

module Bun
  class Configuration
    include CacheableMethods
    
    class << self
      def data_directory
        File.expand_path(File.join(File.dirname(__FILE__), '..','..','data'))
      end
      
      def default_location
        File.expand_path(File.join(data_directory,'archive_config.yml'))
      end
      
      def definitions
        location = File.expand_path(File.join(data_directory,'config_keys.yml'))
        content = ::Bun.readfile(location, :encoding=>'us-ascii')
        YAML.load(content)
      end
      
      def default_keys
        definitions.keys
      end
    end
    
    def default_location
      self.class.default_location
    end
    
    def default_keys
      self.class.default_keys
    end
    
    def keys
      @setting.keys
    end
    
    def definitions
      self.class.definitions
    end
    
    def all_keys
      (keys + default_keys).uniq
    end
    
    def location=(locn)
      @location = locn
    end
    
    attr_accessor :setting
    
    def location
      @location ||= default_location
    end
    
    def initialize(options={})
      @location = File.expand_path(options[:location] || default_location)
      @data = {}
    end
    
    def _read(location=nil)
      location ||= self.location
      content = ::Bun.readfile(location, :encoding=>'us-ascii')
      @setting = YAML.load(content)
      @setting['repository'] ||= ENV['BUN_REPOSITORY']
      @setting
    end
        
    def default_config
      read(default_location)
    end
    cache :default_config
    
    def read(config_file=nil)
      return _read(config_file) if config_file && File.file?(config_file)
      config_file = File.join(location, '.config.yml')
      res = File.file?(config_file) ? _read(config_file) : default_config
      res['repository'] ||= ENV['BUN_REPOSITORY']
      res
    end
    
    def expanded_setting(name)
      expand_path(@setting[name.to_s])
    end
    
    def write(location=nil)
      location ||= self.location
      ::File.open(location, 'w') do |f|
        f.write(YAML.dump(@setting))
      end
    end
  end
end