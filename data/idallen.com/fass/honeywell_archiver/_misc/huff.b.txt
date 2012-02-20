/*  
 *	Huffman encode text. 
 *	Copyright (c) 1978, Alex White   
 *  ccng.wheeler
 */ 


%b/manif/.bset  
optable[] { 
	"Overstrike", DASH_KWD,
	"Runlength", NVAL_KWD, 
	"Usetable", SVAL_KWD,  
	"Table", SVAL_KWD, 
	"noHuff", DASH_KWD,
	"Size", DASH_KWD,  
	"STatisticalfile", SVAL_KWD,   
	-1 
};  
.process 0; 
FILE		=	0;  
OVERSTRIKE	=	1; 
RUNLENGTH	=	2;  
USETABLE	=	3;   
TABLEFILE	=	4;  
NOHUFFING	=	5;  
FILESIZE	=	6;   
STATISTICS	=	7; 
REDIRECTION	=	8;


stats		0;   
tty		0; 
stdin	=	0;  
stdout	=	1; 
s_sector=	64;	/* words per sector */
s_word	=	36;	/* number of bits per word */  
s_printer=	136;	/* number of print positions (for overstrikes) */   
hashtab;
sorted; 
count		0;   
RAW_FLAG=	0600000000000;	/* Small table */  
items		1;	/* always at least eof */ 
RPT	=	0777776; /* Repeated character */ 
rpt_no		5;  
EOF	=	0777777; /* EOF will be huffman encoded */
extern	=	extrn; 
int	=	auto; 
char	=	auto;
s_hash	=	5;	/* size of hash table entry */  
.char	=	[0];	/* The character(s) */ 
.fwd	=	[1];	/* next item in hash table */   


.cnt	=	[2];	/* count of this item */
.bits	=	[3];	/* number of bits in code */   
.code	=	[4];	/* The huffman code */ 
s_tree	=	4;	/* size of huffman tree */  
.item	=	[0];	/* The character(s) */ 
.prob	=	[1];	/* Probability (really count) */   
.conc	=	[2];	/* pointer in huff tree */ 
.bit	=	[3];	/* one bit of huff code */  


main(argc, argv) {  
	extern rpt_no, tty;
	extern .argtyp, sector;
	extern incr, puthuf, stats;
	int size, nohuff, overstr; 
	int f, j, i;   
	int table, outfile, usertable; 


	size = 0;  
	nohuff = 0;
	table = 0; 
	usertable = 0; 
	overstr = 1;   
	/* 
	 *	Parse args. 
	 */
	f = getvec(argc);  
	j = 0; 
	for(i=1 ; argv[i] != -1 ; ++i) {   
		switch(argv[i]>>18) { 
		case STATISTICS:  
			if(stats)
				usage();
			stats = open(argv[i], "wd"); 
			break;   
		case FILESIZE:
			size = !size;
			break;   
		case NOHUFFING:   
			nohuff = !nohuff;
			break;   
		case OVERSTRIKE:  
			overstr = !overstr;  
			break;   
		case RUNLENGTH:   
			rpt_no = *argv[i];   
			break;   
		case FILE:
			f[j++] = argv[i];
			break;   
		case REDIRECTION: 
			if(.argtyp[i] == '>')



				open(stdout, outfile=re(argv[i]), "wbdn");  
			else if(.argtyp[i] == '<')   
				f[j++] = re(argv[i]);   
			else 
				usage();
			break;   
		case USETABLE:
			if(usertable)
				usage();
			usertable = argv[i]; 
			break;   
		case TABLEFILE:   
			if(table)
				usage();
			table = argv[i]; 
			break;   
		} 
	}  
	if(usertable && table) 
		usage();  
	/* 
	 *	Pass 1: make occurance counts   
	 */
	init();
	if(!usertable) {   
		for(i=0 ; i<j ; ++i) {
			open(stdin, f[i], "rd"); 
			if(overstr)  
				over(incr); 
			else 
				raw(incr);  
			close(stdin);
		} 
		if(j == 0) {  
			tty = 1; 
			open(stdout, f[0]="(stdout)", "w");  
			if(overstr)  
				over(incr); 
			else 
				raw(incr);  
			close(stdout);   
			++j; 
			tty = 0; 
		} 
		/*
		 *	Compute the huff codes.
		 */   
		huffcode();   
	} else {   
		open(stdin, usertable, "rbd");
		gettab(); 
		close(stdin); 
		putword('huff');  
	}  
	if(table)  
		open(stdout, table, "wbdn");  
	if(!usertable) 
		puttab(overstr ? 0 : RAW_FLAG);   
	if(table) {
		if(size)  














			printf(-4, "%s is %d sectors*n", table, sector+1);   
		wflush(); 
		close(stdout);
		.write(stdout);   
		putword('huff');  
	}  
	/* 
	 *	Pass 2: Convert the files   
	 */
	if(!nohuff) {  
		putword(0);   
		putword('text');  
		if(j==0)  
			f[(j=1)-1] = ""; 
		for(i=0 ; i<j ; ++i) {
			open(stdin, f[i], "rd"); 
			if(overstr)  
				over(puthuf);   
			else 
				raw(puthuf);
			close(stdin);
		} 
		puthuf(EOF);  
	}  
	if(size)   
		printf(-4, "%s is %d sectors*n", outfile, sector+1);  
	wflush();  
	close(stdout); 
}   


usage() {   
	error("Usage: huff [-noHuff] [-Table] [-Overstrike] [Repeat=n] [infile]***n"); 
}   


/*  
 *	Process each character on a line.
 */ 
processline(line, fun) {
	extern hashtab, items; 
	extern rpt_no; 
	int i, j, k;   


	for(j = 135 ; j>=0 ; j--)  
		if(line[j])   
			break;   
	if(j>=0)   
		line[++j] = '*n'; 
	else   
		line[j=0] = '*n'; 
	for(i = 0 ; i<=j ; ++i) {  
		if(!line[i])  
			line[i] = ' ';   
		for(k=1 ; i+k<=j && line[i+k]==line[i] ; ++k);
		if(k > rpt_no) {  
			i += k-1;
			fun(RPT, k); 
		} 
		fun(line[i]); 
	}  

}   


/*  
 *	Increment the occurance count for a character.   
 */ 
incr(c) {   
	extern hashtab, items; 
	int h; 


	for(h=hashtab[hash(c)] ;   
		 h .fwd && h .char != c; h=h .fwd);   
	if(h .char == c)   
		++h .cnt; 
	else { 
		if(h .char != 0) {
			h .fwd = getvec(s_hash); 
			h = h .fwd;  
		} 
		++items;  
		h .fwd = 0;   
		h .cnt = 1;   
		h .char = c;  
	}  
}   


/*  
 *	Turn the hash table into a sequential table. 
 */ 
table() {   
	int i, h;  
	extern hashtab, count, sorted, items;  


	sorted = getmatrix(items<<1, s_tree);  
	count = 0; 
	for(i=0 ; i<256 ; ++i) {   
		if(!hashtab[i].char)  
			next;
		for(h=hashtab[i] ; h  &&  h .char ; h=h .fwd) {   
			sorted[count].item = h .char;
			sorted[count].prob = h .cnt; 
			sorted[count++].conc = -1;   
		} 
	}  
}   


/*  
 *	Compare function for sorting huff list.  
 *	'Used' items get put at end. 
 */ 
comp(a, b) {
	if(a .conc != -1  &&  b .conc != -1)   
		return(0);
	if(a .conc != -1)  
		return(1);
	if(b .conc != -1)  
		return(-1);   
	return(a .prob > b .prob ? 1 : (a .prob < b .prob ? -1 : 0));  

}   


/*  
 *	Compute the huffman codes for each item. 
 */ 
huffcode() {
	extern stats;  
	extern sorted, count, comp, hashtab;   
	int i, j, k, h;
	int chars, totbits;


	table();   
	for(j=count-1 ; j>0 ; j--) {   
		shellsort(sorted, count-1, comp); 
		sorted[1].bit = 1;
		sorted[0].bit = 0;
		sorted[1].conc = sorted[0].conc = sorted[count];  
		sorted[count].prob = sorted[0].prob + sorted[1].prob; 
		sorted[count].item = 0;   
		sorted[count].conc = -1;  
		++count;  
	}  
	chars = totbits = 0;   
	for(i=0 ; i<count ; ++i) { 
		if(!sorted[i].item)   
			next;
		for(h=hashtab[hash(sorted[i].item)] ; 
			h .fwd && h .char != sorted[i].item ; h=h .fwd); 
		h .code = h .bits = 0;
		for(k=sorted[i] ; k .conc != -1 ; k=k .conc) {
			h .code = (h .code>>1) | (k .bit<<35);   
			++h .bits;   
		} 
		if(h .bits > s_word)  
			error("%d is a lot of bits!*n",h .bits); 
		h .code >>= s_word - h .bits; 
		if(stats) {   
			printf(stats, "'%c'*t",h .char); 
			for(j=h .bits-1 ; j>=0 ; j--)
				printf(stats, "%d", (h .code>>j)&01);   
			printf(stats, "*t%d*n", h .bits);
			totbits += h .bits * h .cnt; 
			chars += h .cnt; 
		} 

	}  
	if(stats)  
		printf(stats, "Average bits: %d.%d*n", totbits/chars, 
			 (totbits%chars)*100/chars); 
}   


init() {
	extern hashtab;
	int i; 


	hashtab = getmatrix(256, s_hash);  
	for(i=0 ; i<256 ; ++i) 
		hashtab[i].fwd = hashtab[i].cnt = hashtab[i].char = 0;
	/* end of file flag! */
	hashtab[0].char = EOF; 
	hashtab[0].cnt = 1;
}   


/*  
 *	Change each overstruck line. 
 */ 
over(funlin) {  
	extern tty;
	int i; 
	char line[s_printer], c;   


	for(i=0 ; i<s_printer ; ++i)   
		line[i] = 0;  
	i = 0; 
	while(c=getchar()) {   
		if(tty)   
			putchar(c);  
		switch(c) {   
		case '*b':
			--i; 
			break;   
		case '*n':
			processline(line, funlin);   
			for(i=0 ; i<s_printer ; ++i) 
				line[i] = 0;
			i = 0;   
			next;
		case ' ': 
			++i; 
			break;   
		case '*r':
			i = 0;   
			next;
		default:  
			line[i] = line[i]<<9 | c;
			++i; 
		} 
		if(i > s_printer  ||  i < 0)  
			error("that's a strange line!*n");   
	}  
}   




/*  
 *	Don't look at the text for overstrikes.  
 */ 
raw(fun) {  
 	extern tty, rpt_no;   




	char c, oldc;  
	int count; 


	oldc = count = 0;  
	while(c=getchar()) {   
		if(tty)   
			putchar(c);  
		if(c == oldc) {   
			++count; 
			next;
		} else {  
			if(count > rpt_no) { 
				fun(RPT, count);
				fun(oldc);  
			} else { 
				while(count--)  
					fun(oldc); 
			}
			oldc = c;
			count = 1;   
		} 
	}  
	if(count > rpt_no) {   
		fun(RPT, count);  
		fun(oldc);
	} else 
		while(count--)
			fun(oldc);   
}   


/*  
 *	Hash the item
 */ 
hash(c) 
	return((c&0377) ^ ((c>>9)&0377) ^ ((c>>18)&0377) ^ ((c>>27)&0377));


/*  
 *	Put out the huffman code table at the start. 
 */ 
puttab(flags) { 
	extern hashtab, items; 
	int i, j, h;   


	putword('huff');   
	putword(flags);	/* leave room for llinks later */  
	putword('tabl');   
	putword(items);
	for(i=0 ; i<256 ; ++i) {   
		if(!hashtab[i].char)  
			next;
		for(h=hashtab[i] ; h ; h=h .fwd) {
			if(flags & RAW_FLAG) 
				putword((h .char << 18) | h .bits); 
			else {   
				putword(h .char);   
				putword(h .bits);   
			}
			putword(h .code);
		} 
	}  
	putword(0);
}   


/*  


 *	Get a huffman table. 
 */ 
gettab() {  
	extern hashtab, items; 
	int h, small;  
	char c;


	if(getword() != 'huff')
		error("not a huffman encoded file*n");
	small = getword() & RAW_FLAG;  
	if(getword() != 'tabl')
		error("no tables*n"); 
	items = getword(); 
	while(c=getword()) {   
		for(h=hashtab[hash(c)] ; h .fwd ; h=h .fwd);  
		if(h .char != 0) {
			h .fwd = getvec(s_hash); 
			h = h .fwd;  
		} 
		h .fwd = 0;   
		if(small) {   
			h .char = c>>18; 
			h .bits = c&0177777; 
		} else {  
			h .char = c; 
			h .bits = getword(); 
		} 
		h .code = getword();  
	}  
}   


/*  
 *	Put out the huffman encoding for a character.
 */ 
puthuf(c, k) {  
	extern hashtab;
	int i, h;  


	for(h=hashtab[hash(c)] ;   
		h .fwd && h .char != c ; h=h .fwd);   
	if(h .char != c)   
		error("no code for '%c'*n", c);   
	for(i=h .bits ; i ; i--)   
		putbit((h .code >> (i-1)) & 01);  
	if(c == RPT)   
		putcnt(k);
}   


/*  
 *	Put out an eight bit repeat count.   
 */ 
putcnt(i) { 
	int j; 


	for(j=7 ; j>=0 ; j--)  
		putbit((i>>j) & 01);  
}   


/*  




 *	put out one binary bit.  
 */ 
buffer	0;   
pos	0;  
putbit(b) { 
	extern buffer, pos;


	buffer = (buffer<<1) | b;  
	if(++pos > 35) {   
		putword(buffer);  
		buffer = pos = 0; 
	}  
}   


sector 0;   
buf[s_sector];  
bpos 0; 
putword(c) {
	extern buf, bpos, sector;  


	buf[bpos++] = c;   
	if(bpos > s_sector-1) {
		write(stdout, buf, sector++, s_sector);   
		bpos = 0; 
	}  
}   


wflush() {  
	extern buf, bpos;  
	extern buffer, pos;
	extern hashtab, sector;


	if(pos != 0) { 
		buffer <<= s_word-pos;
		putword(buffer);  
	}  
	if(bpos != 0)  
		write(stdout, buf, sector, bpos); 
	read(stdout, buf, 0, s_sector);
	buf[1] |= (sector+5)/5;
	write(stdout, buf, 0, s_sector);   
	bpos = 0;  
	sector = 0;
}   


re(a) { 
	auto b[64];


	movelr(b, 0, a, 1, length(a)); 
	movelr(a, 0, b, 0, length(b)+1);   
	return(a); 
}   


rbuffer[s_sector];  
rpos s_sector;  
rsector 0;  
getword() { 
	extern rbuffer, rpos, rsector; 


	if(rpos > s_sector-1) {
		read(stdin, rbuffer, rsector++, s_sector);
		rpos = 0; 
	}  
	return(rbuffer[rpos++]);   

}   
