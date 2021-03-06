_Notes about Bun (GCOS) scripts_

These scripts retrieve and read files archived from the Honeywell GCOS system. They were created in order
to access files from the University of Waterloo (http://uwaterloo.ca/), specifically archived files from the
student theatrical group FASS. (The name is from the Honeywell's affectionate nickname -- the 'bun. For
Honeybun. Get it?)

Thinkage Ltd., in Waterloo, Ontario, Canada maintains the only modern tools for extracting GCOS information
and emulating the GCOS system (that I'm aware of, anyway). Many thanks are due to them, and particularly
to Alan Bowler, who helped greatly in explaining some of the more opaque parts of the GCOS system and file
structures. You can find them on the web at http://www.thinkage.ca/english/index.shtml. For information
about GCOS specifically, check out http://www.thinkage.ca/english/gcos/index.shtml, and particularly the
explain files at http://www.thinkage.ca/english/gcos/expl/masterindex.html

Thanks are also due to Ian! Allen, for his input, suggestions, access to the archives, and encouragement.

_About the software_

This software was written in the Ruby programming language (http://ruby-lang.org/), by Richard LeBer in 
February, 2012. The software is made available under the MIT license -- see the LICENSE file, elsewhere
in this package for details. You may contact the author at mailto://richard.leber@gmail.com.

It is my intent to provide the source for this software on Github, when I get around to it. When I do,
I'll update this note with the address.

The software was developed on an Apple MacBook Pro, running Mac OS X version 10.9.1 and using Ruby version
1.9.3. I can't think of any reason why it shouldn't be portable to other operating systems or versions
of Ruby, including version 2.0, but I haven't tested it, and I make no guarantees.

_Installing this software_

It is also my intent to make this software available as a Ruby Gem. Once I do, you should be able to install
it easily using the gem command, and I will update this note to show how.

At the moment, you will have to take the following steps to install the software:

1. Install Ruby.
2. Install RubyGems
3. Install this software, and put the "bin" directory in your load path
4. Try running it (see below)
5. Install any missing Ruby Gem dependencies (you'll know them from the error messages)
6. Configure file locations: You can do this using the bun config commands
   - Set the default location to store a retrieved archive of GCOS files using the archive entry in the config file.
   - Set the default URL for retrieving archived files (i.e. using "bun fetch"), either by setting the value
     for the repository entry in the config file, or by setting the "BUN_REPOSITORY" environment variable.

_Running this software_

There is one primary executable src/bun. Assuming that the src directory is in your load path, it should
be pretty simple to run the software from the command line, by typing the command "bun". Without any
parameters, the command should provide you with a helpful summary of all the available subcommands.

Many commands are organized as subcommands:
- bun archive
- bun catalog
- bun config
- bun freezer
- bun libray
- bun sandbox

Use "help" with subcommands, as well. For instance "bun archive" lists all the subcommands. One of those 
subcommands is "bun archive index". "bun archive help index" lists help information for that subcommand.

The "bun test" command will run a set of software checks on this software.

_Terminology_
- We refer to a Honeywell backup store of files as a "tape". Typically, this would be the digital image of
  a Honeywell backup tape, stored as a binary file somewhere. Each tape might contain several files, and
  the files might be in several formats, including text files, executable files, listing files (printouts),
  "frozen" archives of files (akin to today's tar archives), or text files compressed using Huffman encoding.
- We expect to start from a collection of tapes: we call an online collection of tapes a "repository". Use
  the "bun fetch" command to download a repository to the local network.
- Once the repository has been downloaded to the local network, we call the collection of tapes an "archive".
  Each such archive contains one file for each tape from the repository. Use the 
  "bun archive" commands to process these files. The archive also has an index, which is processed using the
  "bun archive index" commands.
- The software understands the concept of a "catalog" within the repository or archive. This is a text file
  that lists each archive tape in the archive, one per line. For each archive tape, the row of the text file
  lists the name of the archive tape, its creation date, and the path of the directory archived in the
  archive tape.
- Once files have been decoded, this software refers to that collection as a "library". The "bun library"
  commands are used to process these files.

_File formats_

These scripts were written to decipher old archive tapes from the Honeywell machine at the University of
Waterloo, vintage mid- to late 1980s. This machine used several particular formats, which I only understand
imperfectly. Some salient features:
- The Honeywell machine (often referred to as the "bun", as in "Honeybun"), used 36 bit words.
- There are three formats of archive: text, which archives one file, frozen, which is archives 
  a collection of files (much like modern tar or zip), and huffman, which uses a Huffman encoding scheme

More detailed notes on the file formats (and some old reference programs written in B -- an ancestor of C)
are included in the doc/file_format directory of this project.

_Process_
1. Set up configuration. The "bun config" commands are useful for this. 
2. Use "bun archive fetch" to fetch the repository into the archive.
3. Use "bun archive unpack" to unpack the repository files into an ASCII format (YAML, actually)
4. You can use "bun ls" to list tapes.
5. Optionally, use "bun archive catalog" to apply "last updated" dates from a catalog file.
6. Optionally, use "bun archive text_status" to check the quality of the archived text files.
7. There are a variety of commands you can use to work on individual files:
   - "bun check"    Check if a file is clean
   - "bun describe" Describe a file in the archive
   - "bun dump"     Dump the undecoded contents of a file
   - "bun freezer"  A collection of commands for frozen file archives:
     - "bun freezer dump" Dump the contents of a frozen file
     - "bun freezer ls"   List the contents of the frozen file
   - "bun scrub"    Clean up tabs etc.
   - "bun decode"   Decode a file
8. Use "bun archive decode" to decode files from the archive and place them in a library.
9. Use the "bun library" commands to reorganize the decoded files

