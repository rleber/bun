The Bun project uses the concept of "layers" as the basis for processing files of structured binary data. The
fundamental classes to implement this are contained in the Slicr and Slice classes.

_LAYERS CONCEPT_
Every slice object should descend from Slice::Base, and should be sliceable, e.g. foo.word[0].byte[3].bit[2]
A layer is an array of slices; therefore "layer" is a synonym for "slices"
Define the basic layer "words", which is different than most other kinds of layers, in that the data is stored in words
Other layers may (or may not) store the data, or just reference it from their parent layer
For now, at least, subordinate slices can't overlap the boundaries of slices in the underlying layers, although at their option, layers may define "short" slices to fill up the end of slices in the underlying layer
Therefore, slices in a subordinate layer may not be longer than the slices in underlying layers. So, foo.bytes.six_bits may yield different results than foo.six_bits because the byte alignments will cause bits to be ignored
Every slice has a width
Layers may or may not have a fixed slice width (i.e. the same width for every slice in a layer)
Use layer-esque language: layers lie "on" other layers, layers "support" other layers, layers and slices have "layers" in/on them, etc.

_LAYERS ALREADY DEFINED FOR BUN PROJECT_
- Word, half-word, byte, character, packed character, bit, integer (see lib/bun/word.rb)
- File, archived file, file descriptor (various kinds), blocked file, text file, frozen file, libraries

_LAYERS YET TO BE DEFINED_
- Structures (i.e. a sequence of fields)
- Blocks: e.g. a layer with the same slice size as the supporting layer, but broken into segments
  - Segments of fixed size
  - Segments terminated with a sentinel value
  - Segments with a "size" field somewhere
  - Segments pointed to by a pointer
  - Idea: Base block object takes a Proc which determines its start and length, based on the data
- Bit offset layers: e.g. offset by one bit from base layer, etc.
- Multiword layers: e.g. layers with a slice size a fixed integral multiple of the slices in the supporting layer
