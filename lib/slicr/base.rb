# Class for defining generic machine words

# TODO Write API documentation
# TODO Significant refactoring to get rid of all the dynamic method definitions. For instance, could the 
# API change to word.byte.clipping_mask, and could the slice classes be largely statically defined, and then instantiated
# with a Slice::Definition object?

# TODO Either get rid of this trace stuff, or make it better
$trace = false

require 'slicr/object'
require 'slicr/class'
require 'slicr/string'
require 'slicr/generic_numeric'
require 'slicr/slice'
require 'slicr/word'
require 'slicr/container'
require 'slicr/words'
require 'slicr/block'
