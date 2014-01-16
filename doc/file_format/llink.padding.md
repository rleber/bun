_LLINK PADDING_

There is an issue (as yet unresolved), related to the how llinks from the original archive tapes 
were processed while they were being transferred from the Honeywell to other platforms. During 
this process, extra bits were inserted in the files.

Alan Bowler at Thinkage (atbowler@thinkage.ca) is a pre-eminent expert on Honeywell software. 
As he explained in an email (dated January 14, 2014):

	The archiver would read 12 llinks from the disk (or less
	if this was the last chunk of the file),
	prepend its control info and write this as a block to
	tape.  The first word of the control info is the block
	control word (BCW)
	    bbbbbb nnnnnn
	       bbbbbb is the block number in the tape file (origin 1)
	       nnnnnn number of words in the block not counting the BCW

	The control info had things like the time stamp (seconds since
	01/jan/1900 00:00), the tape number and file on the tape,
	the file name and comment string from whoever asked for the
	file to be archived.  Since this information is variable in
	size, actual number of words in a tape block would vary
	from file to file. (but was constant for the blocks of
	the same tape file).
	A tape frame (byte) is 8 bits of data and a Gcos word is
	36 bits, so each double word ends up as 9 tape frames.
	In the case of an odd number of words being written,
	the last word gets padded with an extra 4 zero bits
	to make 5 tape frames.

	Unfortunately, in the transfers from the original
	archive tapes to Unix and Windows, the extra info
	about the size of each tape block got lost, and all the
	blocks were jammed together in a single file.  So if
	the archive control words are such that the tape block
	was an odd number of words, there are an extra 4 zero bits
	inserted before the data in of the next block.  Thus we need
	to depend on the archive BCW words to retrieve the
	size of the tape blocks and decode the file.

	For example we have looking at file
	  ar061.1840 810610 b/5/dis/blib/readf.g

	after doing bitstream transfer to Gcos we have the
	archive overhead plus data and extra nybbles packed together.

	Looking at the first bit of the first llink we have

	/artest is 31 llinks, dumping for 1 llink
	Llink 0(0):
	000  000001007422 000001000023 000075003460 023122116202  ~~~~ ~~~~ ~=~~ ~RN~
	004  023114001006 000000000000 400000000036 142000000000  ~L~~ ~~~~ ~~~~ b~~~
	010  000000000000 000000000000 000000000000 057065057144  ~~~~ ~~~~ ~~~~ /5/d
	014  151163057142 154151142057 162145141144 146056147040  is/b lib/ read f.g
	020  104151163164 162151142165 164145144000 000001000473  Dist ribu ted~ ~~~~
	024  000024001000 000000000000 000000000000 000000000000  ~~~~ ~~~~ ~~~~ ~~~~
	030  000000000000 000000000000 000000000000 000000000000  ~~~~ ~~~~ ~~~~ ~~~~
	050* 000000000000 000017000600 040040040040 040040040154  ~~~~ ~~~~         l
	054  142154040040 040040040142 164142144054 150066066060  bl      b tbd, h660
	060  060147070056 062071061040 162145141144 146054146157  0g8. 291  read f,fo
	064  162155141164 040143157156 164162157154 154145144040  rmat  con trol led
	070  162145141144 000022000600 040040040040 040040040164  read ~~~~         t
	074  164154040040 040040040150 066066060060 147070056062  tl      h 6600 g8.2
	100  071061040162 145141144146 054146157162 155141164040  91 r eadf ,for mat
	104  143157156164 162157154154 145144040162 145141144040  cont roll ed r ead

	We see the BCW 000001007422 (block 1, 3858 words).  So the
	tape block was an odd number (3859) words.  The actual
	file data starts at word 023 (19) with the BCW of llink 0
	(000001007422).

	So the next tape block will start at word 3859 in the file
	(llink 12 word 19 (023)) but will be 4 bits in.  Looking there

	/artest is 31 llinks, starting at llink 12, dumping for 1 llink
	Llink 12(014):
	000  040040040142 162145141153 073177177177 000001200600     b reak ;~~~ ~~~~
	004  052177177177 000006200600 040040040040 040040040164  *~~~ ~~~~         t
	010  162141040040 040040040056 060060064061 056177177177  ra      . 0041 .~~~
	014  000001200600 052177177177 000000000000 000000000000  ~~~~ *~~~ ~~~~ ~~~~
	020  000000000000 000000000000 000000000000 000000100361  ~~~~ ~~~~ ~~~~ ~~@~
	024  100000040001 140003640163 001145104710 101144600040  @~ ~ `~~s ~eD~ Ad~
	030  300000000000 020000000001 706100000000 000000000000  ~~~~ ~~~~ ~@~~ ~~~~
	034  000000000000 000000000000 002743242746 206447142746  ~~~~ ~~~~ ~~~~ ~~b~
	040  106606446102 747106246046 206302706342 004206447147  F~~B ~F~& ~~~~ ~~~g
	044  207106446107 247206246200 000000640023 700000470030  ~F~G ~~~~ ~~~~ ~~~~
	050  002502503702 002002002002 002002002002 002002002006  ~~~~ ~~~~ ~~~~ ~~~~
	054  146047146242 002342503002 343502006346 747206742006  f'f~ ~~~~ ~~~~ ~~~~
	060  246747143547 740000050030 002507747747 740000300030  ~~c~ ~~(~ ~~~~ ~~~~

	Combing words 023 and 024 we have

	*!/comb 4 000000100361 100000040001
	boff eval (0000000100361<<4)+(0100000040001>>(36-4))\o
	         000002007422

	and see the BCW of tape block 2.  Stepping over the archive overhead
	to words 046 047 we get
	*!/comb 4 000000640023 700000470030
	boff eval (0000000640023<<4)+(0700000470030>>(36-4))\o
	         000015000476

	I.e the BCW for the llink 12 of the file

	Looking further the 3rd tape block will be at word 7718
	(llink 24 word 046) shifted by 8 (4+4) bits.

	/artest is 31 llinks, starting at llink 24, dumping for 1 llink
	Llink 24(030):
	000  747246606202 006406047306 242007146046 446203507747  ~~~~ ~~'~ ~~f& ~~~~
	004  740001010030 002502503702 002002002002 002006446302  ~~~~ ~~~~ ~~~~ ~~~~
	010  402006247407 006746706246 707202003703 642003002002  ~~~~ ~~~~ ~~~~ ~~~~
	014  442006707246 642003642006 707246642002 142502007006  ~~~~ ~~~~ ~~~~ b~~~
	020  747342706746 302707205546 247407006746 706246707205  ~~~~ ~~~~ ~~~~ ~~~~
	024  643547747747 740000640030 002502503702 002002002002  ~~~~ ~~~~ ~~~~ ~~~~
	030  002002002002 002006246607 146242006707 246642003642  ~~~~ ~~~~ f~~~ ~~~~
	034  006707246642 002142742007 006747342706 746302707205  ~~~~ ~b~~ ~~~~ ~~~~
	040  542002646247 407006746706 246707205643 540000000000  ~~~~ ~~~~ ~~~~ ~~~~
	044  000000000000 000000000000 000000006007 444000002000  ~~~~ ~~~~ ~~~~ ~~~~
	050  046000172007 140046244234 404046230002 014000000000  &~z~ `&~~ ~&~~ ~~~~
	054  001000000000 074304000000 000000000000 000000000000  ~~~~ <~~~ ~~~~ ~~~~
	060  000000000000 000136152136 310322346136 304330322304  ~~~~ ~^j^ ~~~^ ~~~~
	064  136344312302 310314134316 100210322346 350344322304  ^~~~ ~~\~ @~~~ ~~~~
	070  352350312310 000000062001 162000034001 400124124174  ~~~~ ~~2~ r~~~ ~TT|
	074  100100100100 100100304352 350100350320 322346100356  @@@@ @@~~ ~@~~ ~~@~

	and doing the shuffle
	/comb 8 000000006007 444000002000
	boff eval (0000000006007<<8)+(0444000002000>>(36-8))\o
	         000003003622

	We see the BCW.  Not that the length is shorter this
	time because this is last chunk of the file.

Let's examine Alan's comments further:
- An llink ("little link" or "block") is:
  - 320 36-bit words (which I will henceforth refer to as lwords)
  - 1,280 9-bit bytes (which I will henceforth refer to as lbytes)
  - 11,520 bits
  - 1,440 8-bit bytes.
- 12 llinks constitute a "link". A link is therefore:
  - 3,840 36-bit lwords
  - 15,260 9-bit lbytes
  - 138,240 bits
  - 17,280 8-bit bytes
- The archival tapes were created in segments. Let's call each such segment a "chunk". 
  Each chunk contains the data for one link.
- During the process of transferring the tape, it was transferred to modern 8-bit systems
  in a process that encoded the data as 8-bit bytes.
- Each chunk contains a prefix, followed by an encoding of the data for the link. The 
  prefix is variable in length, containing information such as the length of the data,
  the time of the archive, and descriptive data provided by the user.
- The data in the prefix repeats for every chunk on the tape. Since most of the data is
  constant throughout the tape, the length of the prefix is constant for every chunk on
  the tape.
- The first word of each chunk is the Block Control Word (BCW). It contains:
  - The block number (starting with 1) in the top 18 bits
  - The number of words in the tape block (not including the BCW) in the bottom 18 bits
- The second word in each block contains the offset of the start of the data in the 
  bottom 18 bits (e.g. 023 in Alan's example)
- The length of the prefix for each chunk may be an even or odd number of 36-bit words:
  - If the chunk contains an even number of 36-bit words, then it is also a whole number
    of 8 bit bytes. In this case, the chunk fits exactly into the 8-bit bytes created
    during the transfer.
  - If the length of each chunk is an odd number of 36-bit words, then it is not a whole
    number of 8-bit bytes: there are 4 extra bits left over. During the transfer process,
    the chunk was padded with 4 zero bits to make a whole number of 8-bit bytes.
- Within each chunk, the data for each link is encoded as a series of llinks. Similarly
  to the encoding of links, each llink is preceded by a BCW for the llink.
  - The top 18 bits are the llink number (again, starting with 1)
  - The bottom 18 bits are the # of words in the llink, not counting the BCW

For further general information, see http://en.wikipedia.org/wiki/General_Comprehensive_Operating_System
