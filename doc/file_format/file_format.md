_Notes on Honeywell File Formats_

These scripts were written to decipher old archive tapes from the Honeywell machine at the University of
Waterloo, vintage mid- to late 1980s. This machine used several particular formats, which I only understand
imperfectly. Some salient features:

- The Honeywell machine (known affectionately as the "'bun", as in "Honeybun") used 36 bit words.
- The files store most signifcant bits first, and most significant bytes first
- There are at least three formats of archive: 
    text:    archives one text file
    huffman: archives one text file with compression by huffman encoding
    frozen:  archives a collection of files (much like modern tar or zip)
  
Because these formats are old and my understanding is imperfect, I make no warranty of the absolutely
correctness of these notes. I encourage you to explore -- you may discover elements of the format which
I haven't figured out yet. If so, please let me know.

If you are looking for more details on the file formats beyond what I have written here, I suggest you
refer to the other files in the doc/file_format directory of this project. These files include:

- decode_help.txt  Some dialog about the characteristics of Honeywell files
- free.b.txt       A program to decode Honeywell's freeze file format, written in B, an ancestor of C
- huff.b.txt       A program to decode huffman coded files, also written in B

The "bun dump" and "bun freezer dump" commands are available to display the contents of files in octal 
and ASCII, and may be useful for exploring files.

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
- Unless otherwise noted, characters are stored one per 9-bit byte, left-to-right, in ASCII. Generally
  it appears that the 'bun used only 7-bit ASCII for character encoding.
- Dates are stored as eight 9-bit ASCII characters "dd/mm/yy"
- Times are stored as 36-bit unsigned integers, in some format I have yet to decipher, although there's
  some relevant code in the B programs
- Integers were stored as signed 36-bit words, with a leading sign bit, and using two's complement format
- Quantities like line length fields, etc. are generally unsigned
- Also a word containing 0170000 is an end-of-file marker. Subsequent data in the file should be ignored.
  I am sure this is true of text files. I have never seen it used in frozen files. I don't know if it
  applies to huffman-coded files.

_All Files_

All files have a "preamble", which includes general information about its name, format, description, etc.
- Word 0:       Always 01 in the upper half-word. The lower half-word contains the size of the file in 
                words UNLESS the file is a frozen file, in which case it should be ignored
- Word 1:       The lower half-word contains the size of the preamble (which contains the file name, etc.)
- Words 7-10:   Contain the archive name (generally the same as the user name of the file owner), as a
                null-delimited string
- Words 11-end: The name of the archived file, and a description, as a null-delimited string. Everything
                after the first space is the description.

_Text Archive Files_

Archive files have the following format:
- They follow the file size shown in word 0 of the file -- that is, data after that may be ignored
- Data may also be terminated by an end of file marker at any time. This is a word containing 0170000
- Following the preamble, as described above, the file is organized as a sequence of 320-word blocks
  - Each block starts with a block length word:
    - The upper half word is the block number (starting at 1 for the first block)
    - The lower half word is the number of bytes used in the block. That is, if a block starts at
      word w, and has a size marker s, then word w+s is the last used word in the block. Words after
      this word (i.e. words w+s+1... w+319) should be ignored
- The data of the file is encoded within the used words in the sequence of blocks. It may be
  conceptually simpler to think of the used words of each block running into the used words of the
  next block (i.e. ignoring the block descriptor word and any unused words at the end of blocks).
- The contents is encoded as a series of lines of ASCII text.
- Lines do not cross block boundaries, and always take an integral number of words.
- Each line is prefixed with descriptor word that includes:
  - Byte 0: Always 0
  - Byte 1: The length of the data in the line in words (not including the descriptor word)
  - Byte 2: A flag word. The valid values seem to be 000, 0200, 0400, and 0600. I have no idea
            what these flag bits signify
  - Byte 3: Always 0600
- The descriptor word is followed by the character data for the line:
  - The number of words of character data is specified in the length field of the line descriptor
  - Characters are packed 4 to a word, one per byte. No more than 7 bits/character are used.
  - No CR or LF characters are included; they are assumed
  - The end of the line may be padded with bytes containing 0177
  - Some control characters may be found, e.g. backspace, tab
- The first line always appears to be a descriptor plus 20 words of 000s. It is ignored.
- End of file markers are optional, but do apply if found. (See above.)

For additional clues, see doc/file_format/decode_help.txt, the source file lib/bun/file/text.rb or 
run "bun dump"

_Huffman Coded Files_

I haven't begun trying to decode these. I will add more notes as I learn how these work. In the 
meantime, refer to doc/file_format/decode_help.txt, or the program doc/file_format/huff.b.txt

_Freeze Files_

Freeze files have the following format:
- Each freeze file includes several archived files or 'shards' (similar to modern tar files)
- After the preamble, there is a general information block of 5 words in length
  - Word 0: The number of words in the file
  - Word 1: Contains the number of shards in the file
  - Words 2 and 3: The date of last update of the freeze file
  - Word 4: The time of last update of the freeze file
- After the general information block comes a series of file descriptors, one for each shard:
  - Each file descriptor is ten words in length
  - The fields in each descriptor are as follows:
    - Words 0 and 1: The name of the archived shard, in 9-bit ASCII characters, padded with spaces
    - Words 2 and 3: The date of last update of the shard
    - Word 4: The time of last update of the shard
    - Word 5: Always the ASCII characters 'asc '
    - Word 6: According to free.b.txt, "The number of 64-word blocks contained in the file."
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
  - Characters are compressed to 7 bits, and stored left-to-right, 5 to a word. The top bit
    of the word is not used.
  - The last character of a line is always a linefeed (LF character, "\r", ASCII code 015)
  - The first word contains a descriptor, plus the first 3 characters of the line:
    - Bits 0-7: Not used. Always 000
    - Bits 8-14: The length of the line, in characters, including the final LF
    - Bits 9-35: The first 3 characters of the line, encoded as described above
  - Subsequent words contain the successive characters for the remainder of the line
- Frozen files don't seem to pay attention to the file size data in word 0 of the file (?)
- They also don't appear to use the end of file marker

For additional clues, see doc/file_format/decode_help.txt, the source file lib/frozen_file.rb or 
run "bun dump" or "bun freezer dump".
