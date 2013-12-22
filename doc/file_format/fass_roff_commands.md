# Copyright 2013, Richard LeBer
# Copied from extract/fass/1982/how.to.roff/howrof.r/tape.ar070.0435_19810901.txt
# I removed extraneous Roff commands from this, for readability

Basic ROFF Information

Roff is a text formatting program that allows you to type in text (in the
case of FASS, your scene) without regard to the final format it will have.
You simply insert some special formatting commands, called macros,
around each character's
speech and before all sound effects, lighting effects and stage
directions.  Roff does the rest.

Roff takes care of things like margins, page headings and footings, page
numbering, and all the other details involved.  Most of these things are
not important if you're just writing an individual scene, and so this explain
will not be very detailed.
For a full story on ROFF, see the ROFF tutorial and manual (explain
roff manual).

There is a macro which lets you abbreviate character names to two letters,
and other macros for things like songs, stage directions, special sound and 
lighting cues.

Each different macro is placed at the beginning of a line, often by itself,
immediately above the line or lines it refers to.
Occasionally, a group of lines (such as a stage direction or song)
will need a macro to end the group too.
Each macro must start a new line, and begin with a period.
A period at the beginning of a line is special to ROFF,
and it will try to find and use a macro named by the two letters following
the period.
ROFF thinks that every line starting with a period ought to be a macro line;
but if it can't identify the two characters following the period,
ROFF just treats the line as text.
This means that lines starting with "..." are okay.

The pertinent macros are as follows:

.so <file>
 - insert an external file, such as the file 80macros
   (this is the first line of every scene)

.bs <act#> <scene#> <"Title of scene">
 - begin scene (this is the second line of every scene)

.na <2chars> <FULL@NAME> <ABBREVIATED@NAME>
 - define a character macro for use by .ch

.ch <2chars>
 - start speech by a character, character defined by .na

.xx <Name@of@characters>
 - give name for a one-use-only character or combination

.bf #lines
 - next line(s) of input to be overstruck three times

.ul #lines
 - next line(s) of input to be underlined

.sp #lines
 - skip blank line(s) on output

.ne #lines
 - make sure a group of lines doesn't split over page

.sd
 - begin a sound direction

.ld
 - begin a lighting direction

.ad
 - begin an acting direction

.ex
 - end any macro; reset to .ch mode

.sb <"Our song title"> <"Real song title or tune">
 - begin a song

.ve <#lines>
 - start another verse of song

.es
 - end a scene (this is the last line of every scene)

Note that many of the macros have "arguments" which must or
may be supplied on the same line as the macro.
These arguments are separated by blanks.
If you want to give an argument to a macro, but the argument itself
contains blanks, replace the blanks in the argument with tildes:

.bs 1 2 This~Is~Act~One~Scene~Two

In most cases, you may also surround the argument with double quotes:

.bs 1 2 "This Is Also Act One Scene Two"

(This will be demonstrated later on.)
More detailed descriptions
of exactly which arguments must be given to each ROFF macro
are given below.

A file containing formatting commands, such as those above, can be expanded
into a fully formatted document by simply typing "roff filename" at system
level, where "filename" is the file containing the text and ROFF commands.
The formatted text may be placed in a file by typing "roff filename >file2"
where "file2" is the place where the formatted (or "roffed") document is to
be placed.  If it does not already exist it will be created as a temporary
file.  You may obtain a printed copy by typing "klist file2"  at system level
(Note that you may also use slist (and NOT tlist) to print it.
Klist should normally be used, to save paper).

Entering a Scene

The following is a sample of how your scene should look:

.bs 1 1 "This is The Title of the Scene"
.na c1 FULL~NAME~OF~CHARACTER1 SHORT~NAME
.na c2 FULL~NAME~OF~CHARACTER2 SHORT~NAME
.na c3 FULL~NAME~OF~CHARACTER3 SHORT~NAME
     .
     .
     .
.na xx FULL~NAME~OF~LAST~CHARACTER SHORT@NAME
.ld
(LIGHTS UP AT START OF SCENE.
ALSO, SOME DESCRIPTION OF WHAT THE STAGE IS LIKE.)
.sd
(YOU MAY ALSO NEED A SOUND DIRECTION,
IF THERE ARE SOUND EFFECTS OR MUSIC TO START THE SCENE.)
.ch c1
This is said by character one.
.ch c2
And this is said by character two.
.sd
(THIS IS ANOTHER SOUND DIRECTION.)
.ld
(HERE IS ANOTHER LIGHTING DIRECTION.)
.ad
(THIS IS AN ACTOR DIRECTION.)
.ch c1
Second speech by character one.
.ch c2
Second speech by character two.
.sb "O Khan-a-Da" "O Canada"
Here are
some song
verses.
.ve 3
This verse
has
three lines.
.ch c1
And character one talks again.
     .
     .
     .
.ld
(LIGHTS DOWN AT END OF SCENE.)
.es *** end of scene ***

Notes

.so 80macros

This inserts the main macro file of macro definitions and
makes sure that a consistent environment is set up in terms of line
length, justification, etc.
Normally the 80macros file is found
in the freeze file containing the script ROFF source.
It must be in your AFT before your try to ROFF anything:

    *free x fass/scripfrz 80macros

.bs 1 1 "This is the title"

Begin a scene.  The first argument is either 1 or 2 for Act I or
Act II.
The second argument is the scene number.
Both arguments must be numbers.
The last argument is the title of the scene, which must be less than
50 characters long!
Remember to put double quotes around the title.

.na c1 FULL~NAME~OF~CHARACTER1 SHORT~NAME

This identifies to ROFF a ROFF macro for your character.
The two character
macro name must be different for each character
in the scene.
The macro can be ANY two letters or digits (even a ROFF
command).
The character macro is used by typing:

.ch <2chars>
This is said by the character.
- for example -
.ch c1
This is said by the character.

The <2chars> are the same as the first argument used in defining the macro with ".na".

The <FULL~NAME> is the full name of the character, which will
appear the first time the character is used in a scene.
After this first appearance, the shorter <ABBREVIATED~NAME> will be used.
Join each word in either name with tildes, so that there are no blanks
in the name.
(Do not use double quotes here!)
The tildes will vanish on output.
Both the full and the shorter names should be UPPER CASE, to set them
off from the rest of the text.

.ad, .sd, .ld

These surround Acting (stage) Directions, Sound Directions, and
Lighting Directions.
These are described elswhere in this document.

.ch c1

This is an example of how to use your character macro.
"c1" was defined using the .na macro.
The argument to .ch must be the exact two characters you used
as the first argument to the .na macro.

.es *** end of scene ***

This is the LAST line of a scene.
Please remember it!

In some cases, you may want to have two characters talk in unison, or you may
have a single-use character who isn't really worth a macro to himself.
You can specify any name to be used just like the regular character macro
would use it by doing:

.xx CHARACTER~1~&~CHARACTER~2

This will format the following speech by the character in the same way
as if you had a macro defined for him.
It is the only way to have two names appear heading one speech.
Make sure you use tildes to join the words together!

Entering Songs

Songs are surrounded by "environment control" macros which set up the
correct indents and lack of fill and justification:

.sb "I'm Dreaming of a White Lemming"  "White Christmas"
I'm dreaming of a white
Lemming.
Just like the mice I used to know
.ve 4
When the days seem
chilly and bright.
May all your shirt collars
Be white.

Notes:

.sb <"Our Song Title"> <"The REAL Song Title">

This sets the titles in a nice box of asterisks, with our song title
first, and the real song title following the words "to the tune of:".
Both titles must be less than 45 characters long.
Make sure that each title is enclosed in a set of double quotes.

.ve 4

This is needed to make sure that a song is not split in the middle of
a verse.  Replace the number "4" by the number of lines up to the next
".ve" or ".se".  This will have ROFF start a new page if it can't fit
the specified number of lines onto the current page; hence, the verse
will be kept together and will start the new page.
Use ".ve~<nn>" to preceed and separate each verse.

Technical and Stage Directions

Stage directions and technical directions for sound and
light must be kept distinct.
This should help our over-worked
technical staff and at the same time make our authors conscious about
the technical demands they are placing.
These directions are very important!

Any sound which must be produced over the P.A. sound system in the Theatre
of the Arts must be surrounded by the ".sd~-~.ex" pair.
This means that noises made by the actors or crew on stage
without the use of the sound system
are NOT sound directions, but are ACTOR directions
(use~.ad~-~.ex).
The piano is NOT a sound direction!

Any lighting changes (including lights up and lights down at the beginning
and end of your scene!) must be surrounded by the ".ld~-~.ex" pair.

Actor (stage) directions, sound directions, and lighting directions
must be surrounded by "environment control" macros, in a similar manner
to songs.
Horrible things happen if you forget to end such directions with
an ".ex" macro!
Here are some sample sound, light, and actor directions:

.ld
(THIS IS AN UPPER-CASE LIGHTING-DIRECTION
WHICH MAY COVER SEVERAL LINES.
IT IS SURROUNDED BY PARENTHESES,
AND MUST END WITH '.EX'.)
.ex

.sd
(THIS IS A SOUND-DIRECTION, USING THE SAME FORMAT.
IT MUST END IN '.EX' ALSO.)
.ex

.ad
(THIS IS AN ACTOR-DIRECTION
{FOR ACTION ON STAGE} USING THE SAME FORMAT.
IT, TOO, MUST END IN '.EX'.)
.ex

Notes:

.ld, .sd, .ad

These begin lighting, sound, and actor directions respectively.
Each ends with the ".ex" terminator (DO NOT FORGET IT!).
These directions are upper case and surrounded by parentheses, to
distinguish them from actors' speeches.

.ex

Exit.  This cancels the environment set up by the preceeding
.ld, .sd, or .ad and restores the previous environment.
PLEASE REMEMBER IT!

For simple directions to the actors, place the short direction in
parentheses in the actor's speech.  Keep such directions upper case!

Example:

.ch fh
(MOVES LEFT) I'm the captain around here! (COUGHS)
Where's Dave?

Light and sound cues should really be surrounded by their macros, no
matter how trivial.  This will mean splitting some speeches around
these directons:

.ch fh
(MOVES TO TELEPHONE) I wonder what will happen next.
.sd
(TELEPHONE RINGS)
.ex
I might have known.  (ANSWERS PHONE) Hello?

Note that another ".ch fh" is not necessary after the sound direction.
The actor will skip the sound direction and continue afterward.
An exception to this rule may occur if the direction is very long,
in which case you should repeat the character macro (e.g. ".ch fh") after
the direction's ending ".ex".

Description of items on stage, such as at the beginning of a scene, is
considered an Actor Direction, to be surrounded by the ".ad~-~.ex" pair.
.ig(nono)**************************************************************
.hd 0 ".ul" Three~Types~Of~Scripts

Scripts may be produced, from the same macro file, in any one of three
formats: Normal, Technical, or Good.
Each format is tailored to suit those who will use it.
Actors use the Normal format, the Director and Technical Crew use the
Technical format, and the script can be formatted for printing using
Good format.

How the script appears is a function of the value of register "TYPE",
which may have the value "0" for Normal, "TECH" for Technical, or "GOOD"
for Good.  Note that Normal is the default, since if the "TYPE" register
is undefined ROFF gives it the value 0.  To produce either of the other
formats, preface the macro file with a file which sets the "TYPE" register:

qed
a
.at(type)
good
.en(type)
'Fw settype
q
:x2
.xs
The file that sets the "TYPE" register should be the very first file
given to ROFF:

    *roff settype+one1+one2+one3+one4 >goodout

Differences in the three Formats

Normal Format:
