#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

module Bun
  class Roff

    def set_time
      now = Time.now
      define_register 'year', now.year
      define_register 'mon',  now.month
      define_register 'day',  now.day
      define_register 'hour', now.hour
      define_register 'min',  now.min
      define_register 'sec',  now.sec
    end

    def define(name, obj)
      name = name.value unless name.is_a?(String)
      @definitions[name] = obj
    end

    def defined?(name)
      name = name.value unless name.is_a?(String)
      @definitions[name]
    end
    alias_method :get_definition, :defined?

    def define_register(name, lines=[], options={})
      v = Register.new(self)
      name = name.value unless name.is_a?(String)
      v.name = name
      if lines.is_a?(Integer)
        v.lines = nil
        v.value = lines
        v.data_type = :number
      else
        v.lines = lines
        v.value = nil
        v.data_type = :text
      end
      v.merge!(options)
      define name, v
    end

    def register_definition(name)
      @definitions[name]
    end

    def value_of(name)
      name = name.value unless name.is_a?(String)
      defn = @definitions[name]
      return nil unless defn
      if defn[:data_format] == :number
        v = defn[:value].to_s
        if defn[:format]
          v = merge(right_justify_text(v.to_s, defn[:format].size), defn[:format])
        end
      else
        v = defn[:lines].join("\n")
      end
      v
    end

    # Set additional values for a definition. values should be a hash
    def set_definition_values(name, values)
      stop "!Can't set values #{values.inspect}. #{name} is not defined" unless defined?(name)
      @definitions[name].merge!(values)
    end

  end
end