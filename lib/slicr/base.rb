# Class for defining generic machine words

# TODO Write API documentation
# TODO Significant refactoring to get rid of all the dynamic method definitions. For instance, could the 
# API change to word.byte.clipping_mask, and could the slice classes be largely statically defined, and then instantiated
# with a Slice::Definition object?

# TODO Either get rid of this trace stuff, or make it better
$trace = false

require 'machine/object'
require 'machine/class'
require 'machine/string'
require 'machine/generic_numeric'
require 'machine/slice'
require 'machine/word'
require 'machine/container'
require 'machine/words'
require 'machine/block'
