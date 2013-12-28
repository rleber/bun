_OBJECT CLASSES IN THE BUN PROJECT_

The Bun project uses several different kinds of classes to represent data objects as well as methods of 
operating on them. The primary categories of these objects are Bots, Files, Data, and Other classes.

_BOTS_
A "bot" is an executable utility that operates on data. An example is the "Freezer" bot, which provides 
operations on "frozen" Honeywell archives (collections of files). Freezer implements a "thaw" method, for
example, which "unfreezes" a file from within an archive.

Bots are implemented using the Thor gem, which helps turn them into command line utilities, with arguments
options, etc. See rubygems or git for further documentation on Thor.

The source file for bots is stored in the lib/bun/buts directory. Generally, each bot has a main file, named 
the same as the bot (plus ".rb"), and a directory with the same name (without the ".rb").
Within the directory are various source files for the bot. Any such source file with a name of the form 
"xxx_task.rb" will automatically be turned into a subtask for the bot. So, for example, the Freezer bot has a 
main file "freezer.rb", and a directory "freezer" which contains (among other things) a "thaw_task.rb" file. 
These bot classes map to a command line command (or subcommand), as defined beginning in lib/bun/bots/main.rb

Bot class hierarchy (indentation denotes inheritance, not naming scope):
Thor
    Bun::Bots::Base
        Bun::Bots::Main
        Bun::Bots::Archivist
        Bun::Bots::Catalog
        Bun::Bots::Config
        Bun::Bots::Freezer
        Bun::Bots::Sandbox

_Files_
There is a hierarchy of File and related classes:
::File
    Bun::File
        Bun::File::Packed
        Bun::File::Unpacked
            Bun::File::Blocked
                Bun::File::Text
            Bun::File::Frozen
            Bun::File::Header
            Bun::File::Huffman
            Bun::File::PackedHeader
        Bun::File::Extracted
        Bun::File::Library
        
Bun::File::Descriptor
    Bun::File::Descriptor::Base
        Bun::File::Descriptor::Unpacked
        Bun::File::Descriptor::Extracted
        
Bun::File::Frozen::Descriptor (note that this does not descend from Bun::File::Descriptor)

Generally, the source files for these classes are found within the lib/bun/file directory, with a source file
name that is derived in a common-sense way from the Class name. So, for instance, Bun::File::Unpacked is in
lib/bun/file/archived.rb, and Bun::File::Descriptor::Unpacked is defined in lib/bun/file/archived_descriptor.rb

_Data Classes_
These classes define various data types and structures:

Bun::Collection (mixes in Enumerable and CacheableMethods)
    Bun::Archive
    Bun::Library

Bun::Configuration

GenericNumeric (mixes in Comparable)
    Slicr::Slice::Base
        Slicr::Slice::Numeric
            Slicr::Slice::Signed::Base
                Slicr::Slice::Signed::TwosComplement
                Slicr::Slice::Signed::OnesComplement
        Slicr::Slice::Unsigned
        Slicr::Slice::String
    Slicr::Structure (mixes in Slicr::Sliceable)
        Slicr::Word
            Bun::Word
            
Slicr::WordsBase
        
::Array
    Slicr::Slice::Array
    
LazyArray (mixes in Indexable::Basic and Comparable)

Generally, the source for these classes is contained in either the lib/slicr directory (for the various Slicr classes),
or in the lib or lib/bun directories.

_Other Modules and Classes_
These classes define various miscellaneous objects and methods, such as:

Bun
Bun::Dump
Bun::Script::Cleaner
Bun::Shell
CacheableMethods
Indexable::Basic
Indexable::Simple
Slicr::Formatted
Slicr::Formats
Slicr::Slice::Accessor (mixes in Indexable::Basic)
Slicr::Slice::Definition
Slicr::Slice::DSL
Slicr::Sliceable

As with the data classes, the source for these classes is contained in either the lib/slicr directory (for the 
Slicr classes), or in the lib or lib/bun directories.

::Enumerator
    Bun::Collection::Enumerator
        Bun::Archive::Enumerator

_Other notes_
The Bun project makes a few changes to Ruby core classes, as well:
Class
Date
Kernel
Object
String
