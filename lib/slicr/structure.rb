#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

require 'slicr/sliceable'

module Slicr
  class Structure < GenericNumeric
    include Sliceable
  end
end