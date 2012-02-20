/*
 *    $0 [-v] <watbun-archive-file
 *
 * Read a watbun tape archive file and extract the data
 * -Ian! D. Allen - idallen@idallen.ca - www.idallen.com
 */

#include <stdio.h>
#include "archiver.h"

static int verbose = 0;
static unsigned char zero[4] = { 0,0,0,0 };
static unsigned char null[4] = { 0177,0177,0177,0177 };

static char translate(char ch);
	int
main(int argc, char **argv){
        int i;
	char *fmt = "";
	unsigned char a, b, c;
	unsigned char dump[8];
	unsigned char raw[8];
	int nr;
	int nbytes;
	int word;
	int skip = 0;
	unsigned char save;
	unsigned char buf[10]; /* at least five bytes - 40 bits */

	if ( argc > 1 && strcmp(argv[1],"-v") == 0 ) {
	    ++verbose;
	    fmt = "%o";
	}

	/* Read alternatingly five bytes (40 bits) and four bytes (32 bits).
	 * Process 36 bits of the 40 bits, save the last four bits.
	 * Add the four bits to the start of the next 32 bits to make 36.
	 */
	for( word=0; (nr=read(0,buf,nbytes = ((word%2) == 0)?5:4)) > 0; word++){
	    	if( nr < nbytes ){
			/* short read - pad with zeroes */
			for( i=nr; i<nbytes; i++)
			    	buf[i] = 0;
		}
		/* If even, save last four bits.
		 * If odd, put saved last four bits in front.
		 */
		if ( (word%2) == 0 ) {
		    save = buf[4]; /* save last 4 bits */
		} else {
		    /* top of first byte comes from bottom of save */
		    buf[4] =               (buf[3]<<4);
		    buf[3] = (buf[3]>>4) | (buf[2]<<4);
		    buf[2] = (buf[2]>>4) | (buf[1]<<4);
		    buf[1] = (buf[1]>>4) | (buf[0]<<4);
		    buf[0] = (buf[0]>>4) | (save<<4);
		}

		verbose && printf("%d/%d %6d %5d %05o  ", nr, nbytes, word*4, word, word);
		/* pull off 9-bit chunks, drop the top bit,
		 * stuff in to 8-bit bytes
		 */
		printf(fmt,a = (buf[0]>>5)&03);
		printf(fmt,b = (buf[0]>>2)&07);
		printf(fmt,c = (buf[0]<<1)&07|(buf[1]>>7)&07);
		verbose && printf(" ");
		raw[0] = a<<6|b<<3|c;
		dump[0] = translate(a<<6|b<<3|c);
		printf(fmt,a = (buf[1]>>4)&03);
		printf(fmt,b = (buf[1]>>1)&07);
		printf(fmt,c = (buf[1]<<2)&07|(buf[2]>>6)&07);
		verbose && printf(" ");
		raw[1] = a<<6|b<<3|c;
		dump[1] = translate(a<<6|b<<3|c);
		printf(fmt,a = (buf[2]>>3)&03);
		printf(fmt,b = (buf[2]>>0)&07);
		printf(fmt,c = (buf[3]>>5)&07);
		verbose && printf(" ");
		raw[2] = a<<6|b<<3|c;
		dump[2] = translate(a<<6|b<<3|c);
		printf(fmt,a = (buf[3]>>2)&03);
		printf(fmt,b = (buf[3]<<1)&07|(buf[4]>>7)&07);
		printf(fmt,c = (buf[4]>>4)&07);
		verbose && printf(" ");
		raw[3] = a<<6|b<<3|c;
		dump[3] = translate(a<<6|b<<3|c);
		
		if ( verbose ) {
		    printf("  ");
		    /* print left-justified to avoid trailing NUL bytes */
		    printf("%-4.4s", dump);
		    if ( raw[0] == 000 && raw[2] == 0170 ) {
			printf(" *** EOF HERE ***");
		    }
		    printf("\n");
		} else {
		    if ( raw[0] == 000 ) {
			if ( raw[2] == 0170 ) break; /* EOF */
			if( memcmp(raw,zero,sizeof(zero)) == 0 ) {
			    // printf("SKIP0");
			    skip = 1;
			    printf("\n");
			    continue;
			}
			if ( skip ) {
			    skip = 0;
			    continue;
			}
			/*
			if ( raw[3] == 0200 ) {
			    printf(" %d ", raw[1]);
			} else {
			    printf(" ?? ", raw[1]);
			}
			*/
			printf("\n"); /* print a newline for 000 words */
		    } else if ( raw[0] == 0177 ) {
			/* a blank record - only has DEL in it */
			if( memcmp(raw,null,sizeof(null)) == 0 ) {
			    printf("\n");
			    continue;
			}
			/* otherwise a deleted record */
			// printf("SKIPD");
			skip = 1;
			// printf("\n");
			continue;
		    } else {
			if ( ! skip ) {
			    /* print left-justified to avoid trailing NUL bytes */
			    printf("%-4.4s", dump);
			}
		    }
		}
	}
	printf("\n");
	return 0;
}
static char translate(char ch){
    if ( isprint(ch) ) return ch;
    if ( verbose && ch == 011 ) return ' ';
    if ( !verbose && ( ch == 010 || ch == 011 ) ) return ch;
    if ( ch == 0177 ) {
	return '\000'; /* 177 bytes pad words - throw them away */
    }
    return '.';
}
