_Notes on Honeywell File Formats_

These scripts were written to decipher old archive tapes from the Honeywell machine at the University of
Waterloo, vintage mid- to late 1980s. This machine used several particular formats, which I only understand
imperfectly. Some salient features:

- The Honeywell machine (known affectionately as the "'bun", as in "Honeybun") used 36 bit words.
- The files store most signifcant bits first, and most significant bytes first
- There are at least two formats of archive: normal, which archives one file, and frozen, which is archives 
  a collection of files (much like modern tar or zip). There may also be some files compressed using a
  Huffman coding scheme.
  
Because these formats are old and my understanding is imperfect, I make no warranty of the absolutely
correctness of these notes. I encourage you to explore -- you may discover elements of the format which
I haven't figured out yet. If so, please let me know.

If you are looking for more details on the file formats beyond what I have written here, I suggest you
refer to the other files in the doc/file_format directory of this project. These files include:

- decode_help.txt  Some dialog about the characteristics of Honeywell files
- free.b.txt       A program to decode Honeywell's freeze file format, written in B, an ancestor of C
- huff.b.txt       A program to decode huffman coded files, also written in B

_Some Notes On Terminology and Conventions_

In what follows:
- A "word" is 36 bits
- A "half-word" is 18 bits
- A "byte is 9 bits (there are therefore four bytes in a word)
- Bit order is assumed to be most significant bit first
- Byte order is assumed to be most significant byte first
- Half-word order is "upper" half-word first, followed by the "lower" half-word
- Indexing is from zero; thus a word has bits 0..35, where bit 0 is the most significant bit
- I use the Ruby convention for numeric literals. For instance 0177 is an octal value (177 base 8).
  Generally, I use octal when discussing bit/byte/word values, because it fits well with 36-bit words.

_All Files_

All files have a "preamble", which includes general information about its name, format, description, etc.
I will write more details later, but for now, I suggest you refer to the source in lib/decoder.rb.

Some other conventions:
- Unless otherwise noted, characters are stored one per 9-bit byte, left-to-right, in ASCII.
  Generally it appears that the 'bun used only 7-bit ASCII for character encoding.
- Dates are stored as eight 9-bit ASCII characters "dd/mm/yy"
- Times are stored as 36-bit unsigned integers, in some format I have yet to decipher, although there's
  some relevant code in the B programs
- Integers were stored as signed 36-bit words, with a leading sign bit, and using two's complement format
- Quantities like line length fields, etc. are generally unsigned
- Unless otherwise noted, characters are stored one per 9-bit byte, left-to-right, in ASCII.
  Generally it appears that the 'bun used only 7-bit ASCII for character encoding.
- Also a word containing 0170000 is an end-of-file marker. Subsequent data in the file should be ignored.
  I am sure this is true of normal archive files; I am less sure in the case of freeze files and huffman
  coded files.

The "gecos dump" command is available to display the contents of a file in octal and ASCII, and may
be useful for exploring files.

_Normal Archive Files_

Archive files have the following format:
- They are encoded line by line, beginning after the preamble
- Each line is prefixed with descriptor word that includes:
  - Byte 0: Usually zero. If not, the subsequent line has been deleted.
  - Upper half-word: The length of the subsequent block of characters _words_
  - Lower half-word: Appears to be some flag information I have yet to decipher
- In the case of a deleted line, the length information should be ignored. The end of the deleted
  data is marked by a word with 000 in byte 0. The next word contains the start of the next line.
- For non-deleted lines, the descriptor word is followed by the character data for the line:
  - The number of words of character data is specified in the length field of the line descriptor
  - No CR or LF characters are included; they are assumed
  - The end of the line may be padded with bytes containing 0177
- The first line always appears to be a descriptor plus 20 words of 000s. It is ignored.
- End of file markers are optional, but do apply if found. (See above.)

For additional clues, see doc/file_format/decode_help.txt, the source file lib/decoder.rb or 
run "gecos dump"

_Freeze Files_

Freeze files have the following format:
- Each freeze file includes several archived files (similar to modern tar files)
- After the preamble, there is a general information block of 5 words in length
  - Word 0: The number of words in the file
  - Word 1: The number of archived files in the freeze file
  - Words 2 and 3: The date of last update of the freeze file
  - Word 4: The time of last update of the freeze file
- After the general information block comes a series of file descriptors, one for each archived file:
  - Each file descriptor is ten words in length
  - The fields in each descriptor are as follows:
    - Words 0 and 1: The name of the archived file, in 9-bit ASCII characters, padded with spaces
    - Words 2 and 3: The date of last update of the archived file
    - Word 4: The time of last update of the archived file
    - Word 5: Always the ASCII characters 'asc '. (Could this have allowed for 'bin '?)
    - Word 6: According to free.b.txt, "The number of 64-word blocks contained in the file."
        I can find no evidence of this being the case, nor have I found it necessary to use
        this data.
    - Word 7: Starting word index of the contents of the file (zero-based offset, relative
        to the end of the preamble)
    - Word 8: The number of words of data in the frozen file. This appears to be generally true,
        except that the last frozen file in the archive extends all the way to the end of the
        file, regardless of what the descriptor says about its length.
    - Word 9: Always 0777777777777
- The frozen data for each file is always in 7-bit ASCII, starting at the word position
  as specified in the descriptor for the file. The data is stored line-by-line. Each line is
  formatted as follows:
  - A line always takes an integral number of words. Excess space is padded with zeros.
  - Characters are compressed to 7 bits, and stored left-to-right, 5 to a word. The top bit
    of the word is not used.
  - The last character of a line is always a linefeed (LF character, "\r", ASCII code 015)
  - The first word contains a descriptor, plus the first 3 characters of the line:
    - Bits 0-7: Not used. Always 000
    - Bits 8-14: The length of the line, in characters, including the final LF
    - Bits 9-35: The first 3 characters of the line, encoded as described above
  - Subsequent words contain the successive characters for the remainder of the line

For additional clues, see doc/file_format/decode_help.txt, the source file lib/defroster.rb or 
run "gecos dump" or "gecos freezer dump".

_Huffman Coded Files_

I haven't explored this format. See decode_help.txt, free.b.txt, or try running "gecos dump".
