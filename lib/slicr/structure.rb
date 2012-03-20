#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

require 'slicr/sliceable'

module Slicr
  class Structure < GenericNumeric
    include Sliceable
  end
end