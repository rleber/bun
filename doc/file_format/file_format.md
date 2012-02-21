_Notes on Honeywell File Formats_

These scripts were written to decipher old archive tapes from the Honeywell machine at the University of
Waterloo, vintage mid- to late 1980s. This machine used several particular formats, which I only understand
imperfectly. Some salient features:

- The Honeywell machine (often referred to as the "bun", as in "Honeybun"), used 36 bit words.
- The files store most signifcant bits first, and most significant bytes first
- There are at least two formats of archive: normal, which archives one file, and frozen, which is archives 
  a collection of files (much like modern tar or zip). There may also be some files compressed using a
  Huffman coding scheme.

If you are looking for more details on the file formats beyond what I have written here, I suggest you
refer to the other files in the doc/file_format directory of this project. These files include:

- decode_help.txt  Some dialog about the characteristics of Honeywell files
- free.b.txt       A program to decode Honeywell's freeze file format, written in B, an ancestor of C
- huff.b.txt       A program to decode huffman coded files, also written in B

_All Files_

All files have a "preamble", which includes general information about its name, format, description, etc.
I will write more details later, but for now, I suggest you refer to the source in lib/decoder.rb.

_Normal Archive Files_

Notably, archive files:
- Are encoded line by line
- Each line is prefixed with its length and what appears to be some flag information I have yet to decipher
- Sometimes, lines are marked as deleted with a special code in the length word
- Lines are padded with nulls

Further details to be written. See decode_help.txt, refer to the source of lib/decoder.rb, or try running:

  gecos dump FILE


_Freeze Files_

Details to be written. See decode_help.txt, free.b.txt, or try running gecos freeze dump.

_Huffman Coded Files_

Details to be written. See decode_help.txt, free.b.txt, or try running gecos freeze dump.
