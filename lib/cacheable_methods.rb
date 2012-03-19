#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# TODO Move this to a Gem

module CacheableMethods
  def self.included(base)
    base.extend ClassMethods
  end
  
  module ClassMethods
    def foo
      puts "bar"
    end
    
    def cache(method)
      original_method = "_#{method}_before_caching"
      instance_variable = "@_cached_value_of_#{method}"
      self.send(:alias_method, original_method, method)
      self.send(:private, original_method)
      def_method method do |*args|
        res = instance_variable_get(instance_variable)
        unless res
          res = self.send(original_method, *args)
          instance_variable_set(instance_variable, res)
        end
        res
      end
    end
  end
end