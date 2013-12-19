_Notes about Huffman Encoded files on Honeywell_

This is a place for notes about how Huffman-encoded (i.e. compressed) files were stored on the old Honeywell
system. For an example of such a file, see the tape "ar116.2128". For notes on Huffman encoding in general, see
the Reference Materials section, below.

_General File Format_
Huffman coded files on the Honeywell begin with the standard file preamble, etc. See other notes under 
doc/file_format for details. For other notes on terminology (36 bit words, etc.), see doc/file_format/file_format.md

_Huffman Table files_
The Huff.b program has capabilities to generate a Huffman encoding table (aka "hash table") file, or to use one 
that has already been generated. The format of such files is as follows:

Word 0     Always "huff"
Word 1     <small flag> Either 0600000000000 (i.e. top two bits on) or zero; determines format of encoding entries
Word 2     Always "tabl"
Word 3     <items> # of entries in hash table
Words 4..  Huffman table entries

If the <small flag> is non-zero, then each entry is stored in two words:
Word 0[bits 18-36]  Character represented by the code
Word 0[bits 0-15]   # of bits in the encoding
Word 1              Encoding

Otherwise, the table uses three words per entry:
Word 0  Character represented by the code
Word 0  # of bits in the encoding
Word 1  Encoding

_Huffman Encoded table format_

Word 0 Always "huff"
Word 1 Flags; if 

_Reference Materials_

- Huffman coding, Wikipedia. http://en/wikipedia.org/wiki/Huffman_coding
- B language source code for huff.b encoding/decoding utility for Honeywell. See doc/file_format/huff.b.txt