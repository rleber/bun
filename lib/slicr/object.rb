#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

class Object
  def singleton_class
    class << self; self; end
  end
end