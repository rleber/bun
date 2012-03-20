#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

class Object
  def singleton_class
    class << self; self; end
  end
end