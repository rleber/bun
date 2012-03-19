#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# TODO Am I necessary?
module Bun
  class File < ::File
    class Raw < Bun::File
    end
  end
end