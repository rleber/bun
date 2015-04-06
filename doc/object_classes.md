_OBJECT CLASSES IN THE BUN PROJECT_

The Bun project uses many different kinds of classes to represent data objects as well as methods of 
operating on them. The primary categories of these objects are Bots, Files, Data, and Other classes.

_BOTS_
A "bot" is an executable utility that operates on data. An example is the "Freezer" bot, which provides 
operations on "frozen" Honeywell archives (collections of files). For instance, Archivist implements a 
"decode" task, which decodes all the files in an archive.

Bots are implemented using the Thor gem, which helps turn them into command line utilities, with arguments
options, etc. See rubygems or git for further documentation on Thor.

The source file for bots is stored in the lib/bun/buts directory. Generally, each bot has a main file, named 
the same as the bot (plus ".rb"), and a directory with the same name (without the ".rb").
Within the directory are various source files for the bot. Any such source file with a name of the form 
"xxx_task.rb" will automatically be turned into a subtask for the bot. So, for example, the Archivist bot has a 
main file "archivist.rb", and a directory "archivist" which contains (among other things) a "decode_task.rb" file. 
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
        Bun::Bots::Test

_Files_
There is a hierarchy of File and related classes:
::File
    Bun::File
        Bun::File::Packed
        Bun::File::Unpacked
            Bun::File::Blocked
                Bun::File::Normal
                Bun::File::Huffman::Base
                    Bun::File::Huffman::Basic
                    Bun::File::Huffman::Plus
            Bun::File::Executable
            Bun::File::Frozen
        Bun::File::Decoded
        Bun::File::Library
    Bun::File::Baked (Note that this does not descend from Bun::File)
    Bun::File::Descriptor::Packed
    Bun::File::Descriptor::Unpacked
        
Bun::File::Descriptor::Base
    Bun::File::Descriptor::File
    Bun::File::Descriptor::Shard
        
Bun::File::Frozen::Descriptor (note that this does not descend from Bun::File::Descriptor::Base)

::Array
    Bun::File::Descriptor::Shards

Generally, the source files for these classes are found within the lib/bun/file directory, with a source file
name that is derived in a common-sense way from the Class name. So, for instance, Bun::File::Unpacked is in
lib/bun/file/archived.rb, and Bun::File::Descriptor::Unpacked is defined in lib/bun/file/archived_descriptor.rb

_Data Classes_
These classes define various data types and structures:

Bun::Data
    Bun::File::Huffman::Data::Base
        Bun::File::Huffman::Data::Basic
        Bun::File::Huffman::Data::Plus

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
Bun::Catalog
Bun::Dump
Bun::Expression
Bun::Expression::Context
Bun::Formatter
Bun::Script::Cleaner
Bun::Shell
Bun::Test
CacheableMethods
Indexable::Basic
Indexable::Simple
Slicr::Formatted
Slicr::Formats
Slicr::Slice::Accessor (mixes in Indexable::Basic)
Slicr::Slice::Definition
Slicr::Slice::DSL
Slicr::Sliceable
String::Trait
String::Trait::Base
    String::Trait::Boolean
        String::Trait::Clean
        String::Trait::Listing
        String::Trait::Overstruck
        String::Trait::Roff
        String::Trait::Tabbed
    String::Trait::Fields
    String::Trait::File
    String::Trait::Numeric
        String::Trait::English
        String::Trait::Legibility
        String::Trait::RunSize
    String::Trait::StatHash
        String::Trait::CountTable
            String::Trait::CharacterClass
                String::Trait::Chars
                String::Trait::Classes
                String::Trait::Controls
                String::Trait::Printable
        String::Trait::FieldValues
        String::Trait::NonEnglishWords
        String::Trait::Runs
            String::Trait::Words
        String::Trait::Stats
        String::Trait::Times
    String::Trait::Wrapper
        String::Trait::FieldWrapper
String::Trait::Base::Result
    String::Trait::Boolean::Result
    String::Trait::Numeric::Result
String::Trait::CharacterPatterns
String::Trait::EnglishCheck

::Array
    String::Trait::CountTable::Result
    String::Trait::FieldValues::Result

As with the data classes, the source for these classes is contained in either the lib/slicr directory (for the 
Slicr classes), or in the lib or lib/bun directories.

::Enumerator
    Bun::Collection::Enumerator
        Bun::Archive::Enumerator

There are also a variety of Exception classes, which for reasons of simplicity (and ease of maintaining 
documentation), I will not include here.

_Other notes_
The ROFF/TF program has a large complement of its own classes, which are documented elsewhere

The Bun project makes a few changes to Ruby core classes, as well:
Array
Class
Date
Hash
Kernel
Object
String
