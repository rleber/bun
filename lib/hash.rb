#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

class Hash
  class << self
    def from_pairs(ary)
      ary.inject({}) do |hsh, pair|
        key, value = pair
        hsh[key] = value
        hsh
      end
    end
  end
  
  def symbolized_keys
    self.keys.inject({}){|hsh, key| hsh[key.to_sym] = self[key]; hsh }
  end
  
  def sorted
    keys.sort.inject({}){|hsh, key| hsh[key] = self[key]; hsh }
  end
end