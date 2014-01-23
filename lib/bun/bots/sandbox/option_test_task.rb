#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

class BaseOptionClass
  class << self
    def option_definitions
      @option_definitions ||= {}
    end

    def option_usage
      superclass_usage = superclass.option_usage rescue {}
      @option_definitions = superclass_usage.merge(option_definitions)
    end

    def option_help
      option_usage.keys.sort.map {|key| option_usage[key]}.map{|hash| [hash[:name], hash[:desc]].join('  ') }
    end

    def option(name, options={})
      option_definitions
      @option_definitions[name] = {name: name}.merge(options)
    end
  end
  option "foo", :desc=>"bar"
  option "option 1", :desc=>"Original description"
end

class InheritedOptionClass < BaseOptionClass
  option "baz", :desc=>"bat"
  option "option 1", :desc=>"Revised description"
end

desc "option_test", "Test inheriting class options"
def option_test
  puts InheritedOptionClass.option_help
end