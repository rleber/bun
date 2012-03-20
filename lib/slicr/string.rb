#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

class String
  # TODO don't define pluralize if it already exists
  def pluralize
    self+'s'
  end
end