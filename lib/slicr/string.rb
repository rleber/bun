#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

class String
  # TODO don't define pluralize if it already exists
  def pluralize
    self+'s'
  end
end