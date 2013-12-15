_Notes about Bun (GCOS) scripts_

These scripts retrieve and read files archived from the Honeywell GCOS system. They were created in order
to access files from the University of Waterloo (http://uwaterloo.ca/), specifically archived files from the
student theatrical group FASS. (The name is from the Honeywell's affectionate nickname -- the 'bun. For
Honeybun. Get it?)

_About the software_

This software was written in the Ruby programming language (http://ruby-lang.org/), by Richard LeBer in 
February, 2012. The software is made available under the MIT license -- see the LICENSE file, elsewhere
in this package for details. You may contact the author at mailto://richard.leber@gmail.com.

It is my intent to provide the source for this software on Github, when I get around to it. When I do,
I'll update this note with the address.

The software was developed on an Apple MacBook Pro, running Mac OS X version ___ and using Ruby version
1.8.7. I can't think of any reason why it shouldn't be portable to other operating systems or versions
of Ruby, including version 1.9, but I haven't tested it, and I make no guarantees.

_Installing this software_

It is also my intent to make this software available as a Ruby Gem. Once I do, you should be able to install
it easily using the gem command, and I will update this note to show how.

At the moment, you will have to take the following steps to install the software:

1. Install Ruby.
2. Install RubyGems
3. Install this software, and put the "bin" directory in your load path
4. Try running it (see below)
5. Install any missing Ruby Gem dependencies (you'll know them from the error messages)
6. Configure file locations: You can do this by setting the values in the file data/archive_config.yml, or with
   environment variables, in some cases:
   - Set the default location to store a retrieved archive of GCOS files using the archive entry in the config file.
   - Set the default URL for retrieving archived files (i.e. using "bun fetch"), either by setting the value
     for the repository entry in the config file, or by setting the "BUN_REPOSITORY" environment variable.

_Running this software_

There is one primary executable src/bun. Assuming that the src directory is in your load path, it should
be pretty simple to run the software from the command line, by typing the command "bun". Without any
parameters, the command should provide you with a helpful summary of all the available subcommands.

_Terminology_
- This software refers to a collection of undecoded Honeywell files as an "archive". Use the "bun archive" commands
  to process these files
- Once files have been extracted, this software refers to that collection as a "library". The "bun library"
  commands are used to process these files.

_File formats_

These scripts were written to decipher old archive tapes from the Honeywell machine at the University of
Waterloo, vintage mid- to late 1980s. This machine used several particular formats, which I only understand
imperfectly. Some salient features:
- The Honeywell machine (often referred to as the "bun", as in "Honeybun"), used 36 bit words.
- There are at least two formats of archive: text, which archives one file, and frozen, which is archives 
  a collection of files (much like modern tar or zip). There may also be some files compressed using a
  Huffman coding scheme.

More detailed notes on the file formats (and some old reference programs written in B -- an ancestor of C)
are included in the doc/file_format directory of this project.
