_Notes about GECOS scripts_

These scripts retrieve and read files archived from the Honeywell GECOS system. They were created in order
to access files from the University of Waterloo (http://uwaterloo.ca/), specifically archived files from the
student theatrical group FASS.

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

_Running this software_

There is one primary executable src/fass. Assuming that the src directory is in your load path, it should
be pretty simple to run the software from the command line, by typing the command "fass". Without any
parameters, the command should provide you with a helpful summary of all the available subcommands.
