_TODO Items_

_ Fix bugs:_
Change meaning of .hy N
    .hy 0  No hyphenation
    .hy 1  Hyphenate at hyphens and hyphenation characters
    .hy 2  (Default) Allow hyphenation before certain suffixes
    .hy 3  "Maximum hyphenation" (between certain pairs of letters)
Tabbing is relative to the current page offset and indentation
Merge patterns have "locked in" offsets, based on the values of .po, .in, and .ll
It appears that .ta should NOT be zero-based (?!)
Treatment of extra tabs
Treatment of tabs (i.e. automatic tabbing mode if there are tabs in the output)
Set .m1, .m2, .m3, and .m4 defaults properly: m1=4, m2=2, m3=1, m4=4
Current .sq is really .nj
Pagination should not print titles or footers that don't fit in the margins
.pl 0 should turn of page breaks (except for .bp requests)
Change "command" to "request" throughout
.at should "ruthlessly suppress newlines wherever possible", in particular at end
Insertions may have parameters
Insertions may be nested
Commands may appear in insertions (and function)
Insertions work in .li text
^(name ...) should result in "0" if name is not defined, and should produce a warning
.name ... should result in a warning
.he and .fo should insist that the delimiter is a non-alphanumeric
Does .ic with no arguments work?
Check how the ^^ pattern works
Redefining a register should throw an error
.at should "lock in" which lines are commands
Parameter substitution should still work after .pc turns off the parameter character
Whitespace at the start of a line should cause an automatic line break
.an NAME (i.e. with no second parameter) sets NAME to 1 (!)
Do we allow "_", "%", and "#" in register names?
If .qc is set to something odd, do .if and .an expressions work?
Are register names case-insensitive?
Do we allow parentheses around register names in .an, .af, etc.?
Two blanks after ":", ".", "?", and "!" at the end of a line
Do tabs work as command/argument separators?
Confirm line break behavior of all commands
Confirm all commands that can take expressions
Does .ce 0 work properly (i.e. turn off centering)?
.ti should shift the results of an immediately preceding .ce
Fix meaning of .m1, .m2, .m3, .m4, .sq
Fix meaning of .ne to account for spacing
Fix line spacing at bottom of pages (i.e. no blank lines at top of next page)
.sp should never insert blank lines at the top of a page
Props list is not working
Are some music cues, i.e. [M-2], etc., missing?
Should there be SFX and sound cues?
Inserts extra spaces at word ends (e.g. "((\nSFX\}"  generates "( SFX )". It should be "(SFX)")
Are we still spreading out spacing on final lines of paragraphs?
Props list line references aren't working. This is because expanding still isn't working quite right.
  It should expand a parameter reference or an insertion, but not both in the same text, I think. Also,
  that may mean that the settings for "don't expand" may not be set right, currently.
.sp n should not insert blank lines at the top of a page
roff only recognizes hyphenation modes 0-3
Check functioning of .if E (E is tested vs. zero)
Stacking of file attachments

_Improvements:_
Other special registers: "%", "#", "%in", "%po", "%ll", "%pw", "%pl", "%ls", "%m1"-"%m4",
    "%amon", "%wday", "%tf"
Other arithmetic operators ("*", "/") in .an (e.g. .an foo *5)
Relational operators ("<", "=", and ">") in .an (set value to 1 if true, 0 if not)
"l" and "s" ("larger" and "smaller") operators
Generalized value of strings in .an and .if expressions (i.e. replaced with size)
Allow multiple operators in expressions
Turn on/off pagination
Specify files for diversions on the command line
Implement notes (.no and .nd)
Optional second parameter to .ti
Change .stop to .ab for compatibility
Add optional N to .mg (Nth merge mask)
Add optional N to .he and .fo (Nth header or footnote)
Implement improved formatting ("i", "I", "a", "A", "o", "O", "z+1")
Eliminate distinction between macros and values (called "registers" in tf)
Improved line breaking: xxx', 'xxx, xxx), (xxx, hyphenation
Justification is generally turned off most of the time. (Although this may be correct.)
Error messages should reference original file names and line numbers
=prefix for disabling expansion
inject method for injecting input lines; refactor multi-line expand using this and =
Additional commands, e.g.
  .st                  Pause (if outputing to a terminal)
  .ix N                Synonym for .di
  .nx                  Synonym for .dn
  .bf N                Bold face
  .pw N                Set page width
  .ig TAG ... .en TAG  Ignore input
  .po N                Page offset
  .bl N                N blank lines
  .bp                  Start new page
  .pa +N               Same as .bp, but set new page number
  .cc CHAR             Set control character
  .ds                  Double space
  .ss                  Single space
  .ef, .eh, .of, .oh   Even and odd page titles
  .hx                  Suppress header titles
  .ix n                .in without line break
  .ln, .n0, .n1, .n2   Line numbering
  .ro, .ar             Roman and Arabic page numbering
  .zt NAME             Delete macro
  .cs CHAR             Set case escape character (overrides .uc and .lc)
  .db CHAR             Use CHAR as a padding character for proportional spacing
  .dc CHAR N [STRING]  Sets the width of CHAR in proportional spacing; replace CHAR with STRING on output
  .ep                  Begin an even page
  .op                  Begin an odd page
  .ff N                Set "line number of top of form"
  .fn TAG ... .en TAG  Divert output to footnotes (note footnotes maintain their own context)
  .ib CHAR             Convert CHAR to blank on input (this may have been added post-FASS)
  .lv N                Leave n blank lines; wait until next page if necessary
  .np N                Do not print next N pages
  .ns N                No filling in first N characters of next line
  .nt                  Return line number of next trap on page
  .nu                  No first character underlining
  .pr N                Print requests in column N -- i.e. trace
  .ps N                Print file/line number information in column N
  .sa NAME             Save register on stack
  .sk N                Skip at next new page to page N
  .sl N                Control formfeeds (0 = don't insert formfeeds; 1 = do)
  .sy COMMAND          Execute system command
  .tb                  Table break
  .tc CHAR             Set "extra" tab character
  .td N                Delete all traps for line N
  .te N                Enable/disable trap processing
  .tn CHARS            Set escape sequence for normal output on output device
  .tf CHARS            Set escape sequence for bold face on output device
  .tu CHARS            Set escape sequence for underlining on output device
  .tl CHARS            Set escape sequence for bold face + underline on output device
  .tp N NAME           When line N is reached, "trap goes off", executing the named register
  .tt TAG ... .en TAG  Divert output to table
  .uf                  Underline first character of every input line
  .ul N                Underline next N lines
  .zt NAME             Pop saved value for NAME

_Extensions_
  Generalized relational operators
  Generalized Ruby expressions
  Allow spaces after control character
  Mode setting comment
