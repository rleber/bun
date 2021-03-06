_Honeywell ROFF_

The archives this software was designed to process were created at the University of Waterloo
in Canada during the late 1970s and 1980s. Many of them were created by the writers of the amateur
theatrical group, FASS. FASS used a text formatting program similar to the modern TROFF to create 
formatted scripts, etc. This program was called Roff or Tf. Some of the files in this archive contain 
Roff/Tf commands, which makes reading them a bit tricky.

For a general tutorial for writers, take a look at doc/file_format/how_to_tf.txt

Roff was similar to (but different from) the family of more modern text processing systems still found
on many Unix systems, like roff, nroff, and troff.

The way this works is, except for "commands" (discussed below), the text formatting program
(which I'm going to refer to as Roff from here on, for sake of simplicity) flows the text
word-by-word into the output, justified as best it can.

Any line starting with a period (".") is interpreted as a command. (No spaces are allowed before 
the period.) They are then followed by a series of arguments, separated by spaces. (There may be 
zero arguments.) Arguments containing spaces are allowed, provided they are enclosed in double quotes 
('"'). Another way to include spaces in an argument is to use "~", which is interpreted as a space. 
(In other words, "~" is similar to the modernescaped space, i.e. "\ ".)

Here's a short summary of some of the most significant Roff commands. Some are built-in primitives;
others are macros:

Primitives             Implemented  Description
--------------         -----------  ------------------------------------    
.pb                             No  Begin paragraph
.so FILE                       Yes  Include a file
.so *list                       No  Insert a list
.li                            Yes  Treat the next line literally; do not interpret any commands in it
.ne <nn> <nn2>                  No  Ensure no page breaks in the next <#> lines; not sure what <nn2> does
.br                            Yes  Break to a new line
.bf NUMBER_OF_LINES                 Set the next few lines in bold face (originally, by 3 overstrikes)
.ul NUMBER_OF_LINES                 Underline the next few lines
.sp NUMBER_OF_LINES                 Skip the specified number of blank lines
.zz STUFF                           A comment
.at NAME ... .en NAME               Set an attribute (or set a macro) with the name NAME
                                        .at (NAME) is also allowed; not sure why
.in NUMBER                          Indent this many spaces
.an ??                              Arithmetic calculation
                                      .an NAME +/-nn  Increments or decrements the named value
                                      .an NAME nn     Sets the named value to nn
                                      Treats undefined variables as zero
.m1 N                               Number of blank lines before page header
.m2 N                               Number of blank lines after page header
.m3 N                               Number of blank lines before page footer
.m4 N                               Number of blank lines after page footer
.ze STUFF                           Issue a warning message (on the console)
.if CONDITION TAG                   If/then/else construct
  .el TAG                           .el is optional
  .en TAG
.fa n *NAME                         Define a buffer, numbered n, referred to by NAME
.dn n TAG ... .en TAG               Divert output into a buffer number n, from here to .en
.cl n                               Close buffer number n
.mg                                 Not sure; the next line seems to define the background characters
                                    used to replace spaces (not including tildes)
.ce NUMBER_OF_LINES                 Center the next so many lines
.pa NN                              Set page number to NN
.he "<left>"<center>"<right>"       Set page heading
.fo "<left>"<center>"<right>"       Set page footing
.ta TABSETTINGS                     Set tabs, e.g.
                                      .ta 3 R +3 +2 L +8 L R 57
.fi                                 Probably "fill" text
.nf                                 Probably "no fill" text
.ju                                 Turn on justification
.sq                                 Squeeze (turn off justification)
.ll +-n or n                        Set line length (?)
.id MACRO TAG                       "if defined"
  .el TAG                           .el is optional
  .en TAG
.ti n                               Temporary indent by n
.uc ... .nc                         Convert input to upper case
.lc ... .nc                         Convert input to lower case
.no TAG                             Not sure; some kind of tag
.pc [CHAR]                          Set parameter flag character (without CHAR, reset it)
.tr abcd                            Translate a->b, c->d, etc.
.ic CHARS                           Change insert characters. I think that if CHARS is a repeated
                                    character (e.g. ^^), then ^^ is the escape for ^, and a single ^
                                    becomes the insert character. This allows embedding in macros.
.pl N                               Set page length
.pw N                               Set page width
.qc CHARS                           Set quoting characters
.fs ...                             Not sure; I think it's footnote separator. E.g.
                                        .fs '____________________'''
.hc CHARS                           Not sure -- hyphenation mark?
.ls N                               Set line spacing
.hy MODE                            Set hyphenation mask (I think). See TRoff manual.
                                        Mask   Meaning
                                        0      Off
                                        1      On
                                        2      Don't hyphenate the last line on a page
                                        4      Don't hyphenate last two letters of a word
                                        8      Don't hyphenate first two letters of a word
.af NAME DIGITS                     I think this may adjust field formatting (e.g. 01)
.po N                               Page offset
.nd N                               Not sure

_Other Notes_

* ^(NAME) expands the named macro. See .ic above
* ^^ is the escape for '^'
* %% is the escape for '%'
* In macros, @1 is converted to the value of the first argument, @2 to the second, etc. Arguments which
  were omitted have a value of ''. See .pc above
* There are two versions of the macros: the "bulk macros" which produce simple scripts meant for mass
  distribution to actors, and the "tech macros", which produce a much more complex script, with line
  counts, etc.
* In arguments, ^(...) works kind of like #{} in ruby or ${} in bash
* Arithmetic operators and comparisons on quoted strings (e.g. "@n") seem to calculate the length of the 
  string, so "@3"<1 asks if the length of @3 is less than one
* ^(%) inserts page number in normal text; in headers and footnotes, it's enough to just say '%'
* A string of more than one space in a line is interpreted as a tab character
* There are several builtin fields, e.g. year, mon, day, hour, min (and probably sec)

Thinkage has a product called tf that is a descendant of Honeywell roff. Some documentation for tf is 
available at http://www.thinkage.ca/english/gcos/expl/tf/expl.html

There is a roff manual at http://www.informatica.co.cr/unix/research/acrobat/790110.pdf that appears to
refer to a version of roff very close to that which was available on the Honeywell.

This version of Roff was similar to (but not exactly the same as) Unix TRoff. A copy of the TRoff User's
Guide is available at http://www.kohala.com/start/troff/cstr54.ps. It's useful for clues. The book Unix 
Document Processing and Typesetting by Balasubramaniam Srinivasan is also useful: http://books.google.com/books?id=VKPBHCWTCGEC

_Tab Stops_

The .ta command uses a tab stop specifier to set tab stops for aligned text. These specifiers are a bit
tricky to understand. Here's how they work:

* Tab stop specifications are a series of the letters L, C, or R, or numbers (possibly with + or - signs),
  each separated by spaces
* If the first entry is numeric, then it's the indentation (as well as a tab stop, possibly). This is _not_
  zero-based, i.e. 3 means indent 3 columns
* Otherwise, all tab stops are zero-based, i.e. a tab stop at 42 means in the 43rd column
* A numeric tab stop without a preceding + or - sign means column n 
* A +n means n columns after the last tab (to the left)
* A -n means n columns before the next tab (to the right)
* The letter R means right stop. Look right in the tab stop specification; the stop is set at the first 
  numeric you find to the right (e.g. R C 53 60 ... would set a right stop at 53)
* The letter L means left stop. Look left for the closest numeric; that's where the stop is (e.g. 42 L means
  "set a left tab stop at column 42, i.e. the 43rd column")
* The letter C means center stop. The stop is set midway between the nearest numerics to the right and left 
  (e.g. 42 C 57 means "set a centered tab at column 49.5". Note that (42+57)/2 = 49.5. That would mean
  centered on the boundary between columns 49 and 50, i.e. the 50th and 51st columns)

   So, for example:
    
     .ta 3 R +3 +2 L +8 L C R 51 R 57
    
   Means "set tabs as follows:"
     - Indent 3
     - First tab stop is a right stop at 6 (3 + 3) -- i.e with its rightmost letter aligned in the seventh column)
     - Next stop is a left stop at 8 (i.e. with its leftmost letter aligned in the ninth column)
     - Then a left stop at 16
     - Then a center stop at 33.5 (because (16+51)/2 = 33.5) -- i.e. with its middle letter aligned halfway
       between the 34th and 35th columns (approximately)
     - Then a right stop at 51
     - Then a right stop at 57

_FASS_

The FASS theatrical troupe created some fairly powerful macros to simplify writing scripts and creating
formatted versions for various purposes, such as use by the director, use by the actors, use by the props
department, and final publication. 

There were several different versions of the macro packages, depending on the purpose for which the script
was being used. Since all of the macro packages shared versions of the same basic macros, this permitted 
the writers to maintain one master script file, which could then be published in several different forms.

Some of the common packages include:

writmacr.t   Produce a script for use by the writers

Please note: In porting these scripts to modern systems, in most cases a ".txt" prefix has been added to
the name of the script files, so writmacr.t becomes writmacr.t.txt, for instance.

_Macros used in FASS scriptwriting_

Macros                              Description
--------------                      ------------------------------------
.bs ACT SCENE NAME                  Begin a scene
.es                                 End scene. Should be the last line of a scene.
.na ABBREV LONG_NAME SHORT_NAME     Define the name of a character. A short and long name are defined.
                                    "ABBREV" is used to define a macro which will be used to start 
                                    speeches by this character. It may be 1-10 letters/digits. Each 
                                    ABBREV must be unique. The long name is used in the script the first 
                                    time each character speaks in a scene, and the short name is used 
                                    for every line thereafter.
.ch ABBREV                          Speech by a character (ABBREV from previous .na command)
.xx NAME                            One off speech by a character (or characters)
.sb SONG_NAME TO_THE_TUNE_OF        Begin a song
.ve NUMBER_OF_LINES                 Begin a new verse
.sl ABBREV                          Similar to .ch for songs
.ss NAME                            Similar to .xx for songs
.x1 .... :x2                        Surround a literal block (Really?)
.ld                                 Begin lighting direction (Continues to the next chunk -- i.e. .ad, 
                                    .sd, .ch, .xx, .sb, .ex)
.ad                                 Actor direction (Again, continues to the next chunk.) Also use this
                                    to describe items on-stage at the beginning of a scene.
.sd                                 Sound direction (Again, continues to the next chunk.)
.md                                 Music direction
.ex                                 The previous actor's speech continues.
.prop NAME                          Signals that a prop is being used
.prip NAME                          Flags an "invisible" prop, which isn't mentioned in the script, but
                                    which does appear on the prop list for the scene.
.star                               A list of 60 asterisks (used by song titles)

_Variables used in FASS scriptwriting:_

Variables          Type             Description
--------------     --------         -----------------------------------
speech_count       Numeric          The total number of speeches so far
chars_defined      Numeric          The number of characters defined so far
chars_used         Numeric          Not sure -- maybe the number of characters who have lines?
song_count         Numeric          The number of songs so far
light_count        Numeric          The number of lighting directions
music_count        Numeric          The number of musical directions
prop_count         Numeric          The number of props
sound_count        Numeric          The number of sound directions
sfx_count          Numeric          The number of sound effect directions
defined            File             List of defined characters
props              File             List of defined props

_Extensions in This Version_

This version of the Roff processor adds some extensions, for the convenience of the user:

Command                             Description
-------                             -----------------------------------
.debug on                           Turn debugging mode on; display command trace, etc.
.debug off                          Turn debugging mode off
.show file NAME                     Display the contents of the named file. You may use '*name' to
                                    display the contents of 'temporary' files (See .fa)
.show file N                        Display the contents of file number N (See .fa, .dn)
.show macro NAME                    Display the definition of the named macro
.show value NAME                    Display the value of the named variable (i.e. from a .an command)
.show stack                         Display the current macro call stack
.show state                         Display key formatting states (e.g. fill mode, tab stops)
.show all                           Display all of the above, for every file, macro, etc.
.stop                               Immediately stop processing

See also the command line options to the bun roff command

The software is also built to be extensible. New commands can be added by adding a <name>_command method
to the class Bun::Roff. (For example, if you add a method foo_command, roff will recognize .foo as a command.)
