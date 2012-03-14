require 'slicr/sliceable'
require 'slicr/cacheable'

module Slicr
  class Structure < GenericNumeric
    include Sliceable
    include Cacheable
  end
end