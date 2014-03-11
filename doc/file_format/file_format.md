_Notes on Honeywell File Formats_

Written by Richard LeBer (richard.leber@gmail.com), January 2014.

These scripts were written to decipher old archive tapes from the Honeywell machine at the University of
Waterloo, vintage mid- to late 1980s. This machine used several particular formats, which I only understand
imperfectly. Some salient features:

- The Honeywell machine (known affectionately as the "'bun", as in "Honeybun") used 36 bit words.
- The files store most significant bits first, and most significant bytes first
- Each archive file contains one file from an archival tape. Tapes were numbered in sequence, and many of 
  them had thousands of files archived on them. Their names are in the form ar999.9999, where the "999" is
  the sequence number of the archival tape, and the "9999" is the sequence number of the archived file on
  that tape
- There are at least five formats of archived file: 
    Type          Contents
    text          One file, usually ASCII text (although see below)
    huffman       One text file with compression by Huffman encoding
    huffman_plus  An extended version of Huffman encoded file, with features for encoding
                  runs of repeated characters, and overstruck characters from printer output
    frozen        A collection of files (much like modern tar or zip)
    executable    A Honeywell executable file 
  
Because these formats are old and my understanding is imperfect, I make no warranty of the absolutely
correctness of these notes. I encourage you to explore -- you may discover elements of the format which
I haven't figured out yet. If so, please let me know.

If you are looking for more details on the file formats beyond what I have written here, I suggest you
refer to the other files in the doc/file_format directory of this project. These files include:

- decode_help.txt       Some dialog about the characteristics of Honeywell files
- programs/free.b       A program to decode Honeywell's freeze file format, written in B, an ancestor of C
- programs/huff.b       A program to encode Huffman coded files
- programs/huff.plus.b  A program to encode Huffman plus format files, also written in B. 
- programs/puff.b       A program to decode Huffman coded files (huff and puff, get it?)

The "bun dump" and "bun freezer dump" commands are available to display the contents of files in octal 
and ASCII, and may be useful for exploring files.

It may also be helpful to explore online. Wikipedia has an entry about GCOS, which was the operating
system on the Honeywell, and later on Groupe Bull machines: 
  http://en.wikipedia.org/wiki/General_Comprehensive_Operating_System

Thinkage Ltd., in Waterloo, Ontario, Canada maintains the only modern tools for extracting GCOS information
and emulating the GCOS system (that I'm aware of, anyway). Many thanks are due to them, and particularly
to Alan Bowler, who helped greatly in explaining some of the more opaque parts of the GCOS system and file
structures. You can find them on the web at http://www.thinkage.ca/english/index.shtml. For information
about GCOS specifically, check out http://www.thinkage.ca/english/gcos/index.shtml, and particularly the
explain files at http://www.thinkage.ca/english/gcos/expl/masterindex.html

Thanks are especially due to my former classmate, Fass Theatre Group friend, and partner in crime, Ian! Allen,
for his input, suggestions, access to the archives, and encouragement.

_Some Notes On Terminology and Conventions_

In what follows:
- A "word" is 36 bits
- A "half-word" is 18 bits
- A "byte is 9 bits (there are therefore four bytes in a word)
- A "sector" was the smallest unit of disk storage. Each sector is 64 words.
- The next largest unit of disk storage was the "llink" (short for little link). Each llink contains 
  5 sectors, or 320 words
- A "link" was the fundamental unit of storage in tape archival files. Each link contains 12 llinks.
- Bit order is assumed to be most significant bit first
- Byte order is assumed to be most significant byte first
- Half-word order is "upper" half-word first, followed by the "lower" half-word
- Indexing is from zero; thus a word has bits 0..35, where bit 0 is the most significant bit
- I use the Ruby convention for numeric literals. For instance 0177 is an octal value (177 base 8).
  Generally, I use octal when discussing bit/byte/word values, because it fits well with 36-bit words.
- Unless otherwise noted, characters are stored one per 9-bit byte, left-to-right, in ASCII. Generally
  it appears that the 'bun used only 7-bit ASCII for character encoding.
- In some cases (see the discussion of media codes below), data was stored as BCD. This uses a 6-bit
  encoding to pack 6 characters into a word. The character set is weird (EBCDIC-like), and is described
  at http://www.thinkage.ca/english/gcos/expl/bcd.html. Some of the formats also provide for "escape 
  sequences" to embed printer control codes in the BCD. This is explained in more detail in the file 
  doc/file_format/bcd_printer_codes.txt
- Dates are stored as eight 9-bit ASCII characters "dd/mm/yy"
- Times are stored as 36-bit unsigned integers. If you are interested in the details, I suggest you look
  at the code in lib/bun/file/data.rb (the Bun::Data.time_of_day method)
- Integers were stored as signed 36-bit words, with a leading sign bit, and using two's complement format
- Quantities like line length fields, etc. are generally unsigned
- Also a word containing 0170000 is an end-of-file marker. Subsequent data in the file should be ignored.
  I am sure this is true of text files. I have never seen it used in frozen files, and it does not apply
  to Huffman or Huffman Plus files.
- Dates were stored as 8 ascii (9-bit) characters, in the sequence "YYYYMMDD"
- Times were stored as a single 36-bit word, counting the number of "ticks" since midnight. It's easier
  to explain this with an algorithm than in words: see the function Bun::Data.time_of_day in 
  lib/bun/file/data.rb for example.
- Note that freeze files contain "time of day" information, but other formats do not. In the case of the
  archive which this software was originally created to decode, we (fortunately) had a "catalog" file
  which contained the names and creation dates of the archives. Several programs, notably "bun archive catalog"
  are designed to work with such a catalog to record the creation date of files. Without such a catalog,
  it is impossible to determine when files (other than freeze files) were created.

_All Files_

All files were stored in tape archives. The tape archives were created in "blocks", with each block 
corresponding to a "link" of data. (Once again, a link is 12 "llinks", each of which is 320 36-bit words.)
Each block in the file has a "preamble", which contains general information about the archived file: its
name, format, description, owner, etc. This information is repeated in each block of the file.
- Word 0:       This word is the Block Control Word (BCW) for the link. Its upper half-word contains the 
                sequence number of the link (starting at sequence number 1). The lower half-word contains 
                the size of the link in words, excluding the BCW.
- Word 1:       The upper half-word contains 1. The lower half-word contains the size of the preamble 
                (which contains the file name, etc.). This length includes the BCW and this word. (In other
                words the length is the offset from the BCW marking where the data begins.)
- Words 2-6:    Flags and stuff. I don't know what they signify.
- Words 7-10:   Contain the archive name (generally the same as the user name of the file owner), as a
                null-delimited string
- Words 11-end: The name of the archived file, and a description, as a null-delimited string. Everything
                after the first space is the description.

After the preamble appears the data for the link. The length of this data is determined by the link length
field in the BCW. Additionally, due to a transcription bug in transferring the data to modern 32-bit systems,
some files may contain an extra four zero bits after some links. See doc/link_padding.md for more details.

The format of the content of each link depend on the format of the file. See below for more details.

Eac archived file is then composed of a series of such links. In some cases, a link with a BCW of all zeros
may occur. This signifies end of file. Additionally, it _may_ be the case (I have some doubt), that a word
containing 0xf000 (Octal 0170000) may mark the end of some files.

So far, I have encountered five types of files (there may well be others). Each has a distinctively different
content and format. As discussed above, these file types are:
- Text files
- Huffman coded files
- Huffman Plus format files
- Freeze files
- Executable files

_Text Archive Files_

While these archive files are most often text, they aren't always. (I should really rename this file type.
The Honeywell system referred to them as GFRC files. "General" might be a better name.) Text archive files 
have the following format:
- The files follow the normal link structure. Content of the file is encoded within that structure.
- Data is usually ASCII text, although some files also contain printer control characters, and in rare
  cases files may contain binary data (e.g. object files or data). I am even told that some archives
  may contain more than one file, with the first llink of the second file following immediately after
  the EOF marker of the first file, etc. I have yet to discover any files of this kind.
- Data may also be terminated by an end of file marker at any time. This is a word containing 0170000. 
  (Actually, I have some doubt about this...)
- Following the preamble, as described above, each link in the file is organized as a sequence of 320-word
  blocks, called llinks. Each llink is always exactly 320 words in length, but the meaningful content of 
  the llink is variable in length; some of the words at the end of the llink may not contain meaningful data.
  - Each llink starts with its Block Control Word (BCW):
    - The upper half word is the llink number (starting at 1 for the first llink). Note: llink numbers are
      sequential throughout the entire file -- the llinks don't start over at llink #1 in the second or
      subsequent links.
    - The lower half word is the number of words used in the llink, excluding the BCW. That is, if an 
      llink starts at word w, and has a size marker s, then s words of data follow the BCW. Therefore,
      word w+1 is the first word of data, and word w+s is the last word of data in the llink. Words 
      after this (i.e. words w+s+1... w+319) should be ignored.
- The data of the file is encoded within the used words in the sequence of llinks. It may be
  conceptually simpler to think of the used words of each block running into the used words of the
  next llink (i.e. ignoring the block control word and any unused words at the end of llinks).
- The content is encoded as a series of records of data. Usually (see media codes below), this is lines 
  of ASCII text.
- Records always take an integral number of words. Usually, they do not cross llink boundaries. When they
  do, they are broken into "segments", which don't cross llink boundaries. This software currently does 
  not understan segmented records.
- Each record is prefixed with a record descriptor word (RCW) that includes flags describing the data
  in that record (for more details, see emails in doc/file_format/):
    Bits   Name            Description
     0-17  length          Length of record/segment (must be non-zero)
    18-19  final_bytes     # of bytes of data in last word of record (media types 4 & 6)
                                A value of zero is interpreted to mean 4 bytes
    20-23  eof_type        EOF type (when length in bits 0-17 is zero)
    24-25  segment_marker  Segment marker, distinguishes multi-segment records
                             0: Not segmented, this is the first and only segment
                             1: First segment of record split across blocks
                             2: Intermediate segment
                             3: Last segment
    26-35  segment_info    Interpretation depends on the value of segment marker
  - For segment markers 0 or 1:
    - Bits 26-29: Media code. 
      For a more complete explanation, see http://www.thinkage.ca/english/gcos/expl/medi.html
      This software has a rudimentary understanding of media codes other than 6 and 7
        0: Variable length BCD text
        1: Binary data, variable length or card image. Used for object "decks" (remember, this
             software was originally created in an era when people did everything with 80-column
             punch cards!), and compressed source decks. When records contain binary card images,
             they are always 27 words long.
        2: Card image BCD. Records are always 14 words long.
        3: Print image BCD. Records always contain printer control codes. See doc/file_formats/
           bcd_printer_codes.txt for an explanation of these printer control codes.
        4: User-specified format. Used by University of Waterloo B programs for output of binary
             streams. Other formats may exist, but translation is not guaranteed.
        5: "Old format" TSS ASCII. Not used and not supported.
        6: Standard ASCII text. This is the only media code this software currently understands.
        7: Print image ASCII. Standard ASCII, but containing printer control codes.
        8: The media control code of the file header of most media 6 (ASCII) files. Records are
             always 20 words.
        9: Special print image BCD. Like media code 3, but the first two bytes of each record
             contain an extended report code (which the Thinkage software ignores).
        10: Card image ASCII.
        13: Special print image ASCII. Like media code 7, but the first two bytes of each record
             contain an extended report code (which the Thinkage software ignores).
    - Bits 30-35: Report code
  - For segment markers 2 or 3:
    - Bits 26-35: Segment number (zero origin)
- The record descriptor word is followed by the data for the record. For ASCII (media code 6) records,
  that data is encoded as follows:
  - The number of words of character data is specified in the length field of the line descriptor word
  - Characters are packed 4 to a word, one per 9-bit byte. No more than 7 bits/character are used.
  - No CR or LF characters are included; they are assumed at the end of each line.
  - The end of the line may be padded with bytes containing 0177. These should be ignored. (Technically,
    this should be accounted for by the final_bytes field, except in the case where the line has zero
    characters in it. In this case, I have generally found that the line is encoded as one word, with
    final_bytes set to 1 (because zero would mean 4 bytes), and the first byte of the line is 0177.)
  - Some control characters may be found, e.g. backspace, tab
  - In the case of BCD data, this software converts it to ASCII. It does not make any attempt to convert
    printer control codes to ASCII control characters (or perform any other conversion on them).
  - In the case of binary data, this software converts it to binary (i.e. an whole number of 8-bit bytes
    of binary data), followed by a carriage return. (This may not be exactly right, but it's what the
    software does, right now.) Because 9-bit bytes may not fit evenly into 8-bit bytes, the line may
    be padded with zero bits at the end, before the carriage return.
- In ASCII files, the first line always appears to be a file header with a descriptor (media code 8),
  plus 20 words of 000s. It is ignored.
- End of file markers are optional, but do apply if found. (See above.)

Occasionally, these files can get messed up. In particular, a line descriptor may be missing, or 
not in the expected place. In that case, this software attempts to find the next line descriptor
word and interpret the intervening words as words of text.

For additional clues, see doc/file_format/decode_help.txt, the source file lib/bun/file/text.rb or 
run "bun dump"

_Huffman Coded Files_

Some files were compressed before being saved. The Honeywell used a simple Huffman encoding scheme for
compressing files. This scheme results in a minimal-length encoding through the encoding each 9-bit byte 
using a translation table (a binary tree, actually), and a variable number of bits per encoded character
(with the fewest bits for the most common characters, etc.). See http://en.wikipedia.org/wiki/Huffman_coding for general information on Huffman encoding.

The original source for the Honeywell's encoding algorithms is contained in the doc/file_formats/programs/huff.b
puff.b files.

The format for Honeywell Huffman-encoded files is as follows:
- The files follow the normal link structure. Content of the file is encoded within that structure. They do
  not use the llink structure contained in text files.
- The file contains first the Huffman encoding translation table/tree, followed by the encoded text.
- The first word after the preamble of the first link should contain 'huff'
- The next word contains the number of characters in the encoded text in bits 1-17. (Bit 0 encodes
  something, but I'm not sure what.) There's some information encoded in the remainder of the word, too, 
  but I can't figure out what it means.
- After the first two words begins the Huffman encoding tree. Taking each 9-bit byte in turn, they
  encode a binary tree, using the following algorithm:
  - Examine a byte. If it is zero, then you are at a leaf of the tree, and the next byte contains the 
    character at that leaf
  - Otherwise, the byte is the number of nodes down the left-most arm of the tree. Recursively define
    the subtrees (in depth-first fashion), as follows: Start the description of the left subtree by 
    reusing the byte that began the description of its parent, minus one. Once you have decoded the
    left subtree, the description of the right subtree begins with the next byte in sequence.
  - If the above isn't clear, look at File::Unpacked::Huffman#make_tree
- The next 9-bit byte following the tree is ignored. I'm not sure what it contains, but it isn't text.
- Then, the next 9-bit byte begins the encoded text. Since Huffman encoding works bit-by-bit, the text 
  must be examined one bit at a time, traversing the Huffman tree from the top. At each bit, a "0" bit
  means take the left branch of the tree, and a "1" bit means take the right branch. When you reach a leaf,
  that's the encoded character. See the Wikipedia article for more information on the encoding algorithm.

Note that the Huffman encoding algorithm doesn't care how many bits are in a "character". Because most
Honeywell files were encoding as 8-bit characters stored in 9-bit bytes, this mostly is irrelevant. However,
some files may include 9-bit characters encoded in Huffman format. When this is the case (which seems mostly
to be object files of some kind), this software outputs the decoded file in binary format. To be more specific,
if ANY character in the file is more than 8 bits, every character is treated as 9 bits, which are combined
into 36-bit words and then output in binary format. (Note: 36-bit words may not fit evenly into 8-bit bytes.
Because of this, the resulting output may have 4 additional zero bits appended to the end of it, to fill
out the last byte.)

_Huffman Plus Files_

These files are encoded with an extended Huffman encoding format, which also has features for run-length
compression and handling overstruck characters (see the sidenote below, if this is a confusing concept for
you). The "Huffman Plus" name is my own, but it seems to fit.

Like regular Huffman files, Huffman Plus files begin with a Huffman encoding tree. However, the tree is 
stored in a different format in the file. In addition to the Huffman compression, the format provides for
overstriking of up to four characters, and also for compressing runs of identical characters.

The format works as follows:
- As with Huffman files, the normal link structure is followed, but llinks and RCWs are not used.
- The file contains first the Huffman encoding translation table/tree, followed by the encoded text.
- The first word after the preamble of the first link should contain 'huff'
- Unlike the normal Huffman format, the next word primarily contains the number of links in the lower
  word (I think -- although my software ignores it), and a "small tree/overstrike" flag in the top two
  bits of the word. More specifically, if the top two bits of the word are both ones, then the small
  tree format is used, and overstruck characters are not encoded; otherwise, they are.
- The next word should contain 'tabl'. Again, this is different from the normal Huffman format
- The next word should contain the number of characters encoded in the Huffman encoding tree.
- Then, there follows the nodes describing the encoding, one for each encoding. Depending on the
  setting of the "small tree" flag described above, each node is either 2 or 3 words long.
  - If the "small tree" flag is set, each node is two words long
    - The file does not provide for overstruck characters
    - Each node describes one character encoded in the file
    - Bits 0-17 of word 0 are the character (which could theoretically therefore be 18 bits, but
      which I haven't found an example of)
    - Bits 18-19 of word 0 aren't used
    - Bits 20-35 of word 0 contain the number of bits in the encoding
    - Word 1 of the node contains the encoding in its lowest bits (i.e. nn..35)
  - If the "small tree" flag is not set, then each node is three words long
    - Word 0 contains the characters. Up to four characters may be included in the word, one in each
      9-bit byte. Unused characters contain binary zeros. If more than one character is included, that
      means that they were overstruck. For instance, a word containing (in 9-bit encoding) "\0\0C_"
      would be for the encoding of an underlined capital "C". In practice, the characters always seem
      to be in the lowest order bytes of the word, padded with zeros at the top.
    - Word 1 contains the number of bits in the encoding
    - Word 2 contains the encoding in its lowest bits (i.e. nn..35)
- After the tree may come a few zero words, which are ignored
- Then there should be a word containing 'text', followed immediately by the encoded text
- Unlike the basic Huffman encoding format, there is no "number of characters" field. Instead, the
  text includes a special EOF character. Once that character is encountered (in its Huffman encoded
  form), that marks the end of the file. This EOF character is represented by the 18 bits 0777777,
  although (of course) after Huffman encoding, it might be any arbitrary assigned sequence of bits.
- The encoded text also contains provisions for compressing runs of identical characters. This is
  represented in the encoded text as a special REPEAT character (encoded, as with the EOF character).
  The unencoded value of the REPEAT character is the 18 bit sequence 0777776. After this character
  is found (in encoded form) in the text, it should immediately be followed by:
  - 8 bits encoding the number of times the repeated character repeats (i.e. 0-255 times). Because
    Huffman encoding uses a variable number of bits, these 8 bits are the next immediate 8 bits after
    the end of the encoded REPEAT character, regardless of byte boundaries, etc.
  - After the repeat count should appear a Huffman encoded character, which represents the character
    to be repeated. This might be an overstruck character, as described above.
  - As an example, if RPT is the sequence of bits representing the REPEAT character in the Huffman
    encoding and 11 encodes a space, then RPT 00010001 11 encodes a string of 17 repeated spaces
- Other than ending at an EOF character, the encoded text works in exactly the same manner as with
  basic Huffman encoded files
- A sidenote about overstriking:
  - These files were created in the days before dot matrix, inkjet and laser printers. Most printers
    worked by physically hammering type face elements into an ink tape and pressing ink from the tape 
    onto paper, in a similar manner to a typewriter
  - Because of this, there were no "fonts", and the characters available were limited by the physical
    print elements in the printer.
  - To create more diverse printing (for example underlined characters), many printers used overstriking:
    that is, they printed more than one character onto the same space on the paper
  - This was signified either by using the CR character to return to the start of the same line on
    the paper and print it again, or by the BS character to back up to the previous print position
  - This software encodes overstrikes using the BS character. So an underscore printed over a "C"
    would be encoded as "C\b_" (or perhaps "_\bC")

_Freeze Files_

Freeze files have the following format:
- The files follow the normal link structure. Content of the file is encoded within that structure. They do
  not use the llink structure contained in text files.
- Each freeze file includes several archived files or 'shards' (similar to modern tar files)
- After the preamble of the first link, there is a general information block of 5 words in length
  - Word 0: The number of words in the file
  - Word 1: Contains the number of shards in the file
  - Words 2 and 3: The date of last update of the freeze file (date format is described above)
  - Word 4: The time of last update of the freeze file (time format is described above)
- After the general information block comes a series of file descriptors, one for each shard:
  - Each file descriptor is ten words in length
  - The fields in each descriptor are as follows:
    - Words 0 and 1: The name of the archived shard, in 9-bit ASCII characters, padded with spaces
    - Words 2 and 3: The date of last update of the shard (see above for format)
    - Word 4: The time of last update of the shard (see above for format)
    - Word 5: Always the ASCII characters 'asc ' (note the space)
    - Word 6: According to free.b, "The number of 64-word blocks contained in the file."
        I can find no evidence of this being the case, nor have I found it necessary to use
        this data.
    - Word 7: Starting word index of the contents of the shard (zero-based offset, relative
        to the end of the preamble)
    - Word 8: The number of words of data in the shard. This appears to be generally true,
        except that the last frozen file in the archive may extend all the way to the end of the
        file, regardless of what the descriptor says about its length.
    - Word 9: Always 0777777777777
- The frozen data for each shard is always in 7-bit ASCII, starting at the word position
  as specified in the descriptor for the file. The data is stored line-by-line. Each line is
  formatted as follows:
  - A line always takes an integral number of words. Excess space is padded with zeros.
  - The first word of each line contains a descriptor, plus the first 3 characters of the line:
    - Bits 0-7: Not used. Always 000
    - Bits 8-14: The length of the line, in characters, including the final LF
    - Bits 9-35: The first 3 characters of the line, encoded as described below
  - Subsequent words contain the successive characters for the remainder of the line
  - Characters are stored as 7-bit ASCII. They are stored left-to-right, 5 to a word, starting at
    the second bit in the word. The top bit of the word is not used.
  - The last character of a line is always a linefeed (LF character, "\r", ASCII code 015)
- They also don't appear to use the end of file marker

For additional clues, see doc/file_format/decode_help.txt, the source file lib/frozen_file.rb or 
run "bun dump" or "bun freezer dump".

_Executable Files_

I have done a little bit of work on this format. The only example in the FASS archive is ar010.1307.
There are some files in the doc/file_format directory (qstar-format.pdf, qstar.c and l-code.c) that
will give you a clue. Also worth referencing is the code in Bun::Data#modules. This code is enough
to allow this software to distinguish executable files from non-executable ones. Beyond that, I know
little. (And since I have no way to execute the executables, I'm not working that hard to find out.)

Here's what I do know:
- They contain links
- They do not contain valid llinks
- They contain a series of named modules
- They're organized in sectors
- The data is binary.
