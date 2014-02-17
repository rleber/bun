/*
!b  cmdlib/s/huff  cmdlib/huff  n
*/
main(){
		/*  Huffman encoding of files **********/

	auto inrc[10], rec[ 30 ], freq[ 10 ], i, j ;
	extrn in.opts, in.des, in.tot, in.atual, in.tab, in.ptr, in.refr, in.sk, in.tal, in.of;
	extrn out.opts, out.des, outtab, out.ptr, out.refr, out.max, outrec;
	extrn wd1, out.sk, huf.opn, acc.fil, huf.rd, chaget, huf.rew, hufrrw;
	extrn huf.get, hufsop;

	/* initialise random input */
	huf.opn = acc.fil;
	huf.rd = chaget;
	huf.rew =hufrrw;
	wd1 = 0;

	reread();
	getstr( rec );
	i = getarg( freq, rec, 0 );
	i = getarg( inrc, rec, i, " *t(;" );
	if( char( rec, i-1 ) == '(' ){
		i = getarg( freq, rec, i, " *t;" );
		if( (char( freq, 0 )| ' ' ) == 'a'){
			huf.opn = hufsop;
			huf.rd = huf.get;
			huf.rew= hufsop;
			wd1 = 0400000000000; }
		else	in.tot = gnumber( freq, 0 ); }
	else	in.tot = 0;

	in.atual = 0;
	i= getarg( freq, rec, i );
	huf.opn( inrc, in.opts, in.des ); /*opening files */
	acc.fil( freq, out.opts, out.des );
	if( !in.tot & !wd1 ) in.tot= (in.des[4] & 07777 ) *
		( ( in.des[4] &0400000 ) == 0 ? 12 : 1 );
	out.max = ( out.des[4] & 07777 ) * ( (out.des[4] & 0400000 ) == 0 ? 60 :5 );

	/* initialise i/o tallies */

	cleanb( in.tab );
	cleanb( outtab );
	out.ptr = out.refr; /* output starts with empty buffer */

	/* generate table of frequencies and encodings */

	i = huffgen(  tblgen() ) ;

	/* to rewind input file */

	huf.rew( inrc );

	encode( i );
	for( j=0; j<=7; ++j) putbit( 0 ); /* flushing bit bucket */
	writeb( ); /* flushing buffer */

	out.des[2] = 0;
	ran.rd( out.des, outrec );
	outrec[0]= 'huff';
	outrec[1]= wd1 | (out.sk/5); /*plug this files size */
	out.des[2] = 0;
	ran.wr( out.des, outrec );
	printf( "*n %c%c is %d llinks*n",
		out.des[0], out.des[1], out.sk/5);
	if(wd1 > 0)	if( ( in.des[ 4 ] & 040000 ) != 0 ) retfil( in.des );
	if( ( out.des[ 4 ] & 040000 ) != 0 ) retfil( out.des );
	exit();
/* end of main */ }
tblgen(){

	extrn comp.w;
	auto i,freq;

	freq = getvec(512);
	for( i=0; i <= 511; ++i) freq[ i ] = i;
	while( ( i= huf.rd() ) >= 0 ){
		freq[ i ]=+ 01000;
		/* end of while */ }
	shellsort(freq, 512,comp.w );
	return( freq );
/* end of tblgen */ }


comp.w( a, b)

	/*shell's sort compare */
	return( a>b ? -1: 1 );


chaget(){

extrn in.ptr, in.of, in.tal;

	if( in.ptr > in.of ) /* new buffer is needed */
		if( readb() < 0 ) return( -1 ); /* to read new buffer */
	return( @in.tal );
/* end of chaget */ }


readb(){

	extrn in.des, in.sk, in.atual, in.tot, in.rec, io.stats, in.ptr, in.refr;

	in.des[ 2 ] = in.sk;
	in.sk =+5;
	if( ++in.atual  > in.tot ) return(-1);
	ran.rd( in.des, in.rec );
	if( ( io.stats & 0170000000000) == 0170000000000 ) return(-1);
	in.ptr = in.refr;
	return(0);
/* end of readb*/}

huf.get(){
	auto i;
	if((i = getcha())=='*e')return(-1);
	return(i); }



hufrrw(){
	auto rec[2];
	extrn in.ptr, in.of, in.sk, in.des, in.atual;

	in.ptr = in.of + 1;
	in.sk = 0;
	if( ( in.des[4] & 0200000) == 0 ) drl.drl( 012 /*rew*/, (in.des <<18| rec));
	in.atual =0;
/* end of hufrrw */ }

hufsop( file ) /* ignoring next 2 args */ openr(2, file);


writeb(){
	extrn out.des, out.sk, outrec, out.ptr, out.refr, io.stat, out.max;

	/* check addrs is outside file*/

	if( out.sk >= out.max ){
		auto xxx[160];
		drl.gro( out.des, xxx );
		if( ( io.stat & 0377700000000 ) != 0){
			printf("%c%c file error %12o *n",out.des[0],out.des[1],io.stat);
			exit(); }
		
		/* update out.max */

		out.max =+ (out.des[4] &0100000 ) == 0 ? 60 : 5; }
	out.des[ 2 ] = out.sk;
	out.sk =+ 5;
	ran.wr( out.des, outrec );
	out.ptr= out.refr;
/* end of writeb */ }


chaput( chart ){

	extrn out.ptr, out.tal, out.of, out.refr;

	@out.tal = chart;
	if( out.ptr > out.of ){   /* buffer is full */
		writeb();
		}
/* end of chaput */ }



putbit( bit ){

	extrn biting ;

	if( (biting = ( biting << 1 ) | bit ) >= 01000 ) {
		chaput( biting );
		biting = 1; }
/* end of putbit */ }


outtb( c, last ){

	if( *last == 0 ){
		chaput( c );
		chaput( last[ 1 ] ); }
	else {
		outtb( ++c, *last );
		outtb( 0, last[ 1 ] ); }
/* end of outtb */ }



walk( head ){

	auto encod, siz;
	extrn encd, work, wrkpos, wrkrefr, wrksc, wrkscr;

	if( !head[ 0] ){

		/* character found */

		siz = ( wrkpos >> 18 ) - work ;
		@wrksc = 2; /* signalling end of encoding */
		encod = getvec( siz );
		copy( encod, work, siz );
		@wrkscr = @wrkscr = 3; /* to back tally */
		encd[ head[ 1 ] ] = encod; /* store heading */
		return ; }

	@wrksc = 0;
	walk( head[ 0 ] ) ;
	@wrksc = 1;
	walk( head[ 1 ] );
	@wrkscr = 4;
	return;
/* end of walk */ }





putenc( head ){

	auto c;
	extrn wrkhd, wrkhsc;

	wrkhd= head << 18 ;
	while( (c = @wrkhsc ) <= 1 ) putbit( c );
	return ;
/* end of putenc */ }

encode( i ){

	auto c;
	extrn encd, work, wrkhd, wrkpos, wrkrefr, wrksc, wrkscr, wrkhsc;

	/* first gen encodings */

	wrksc = ( &wrkpos << 18 ) | 052;
	wrkhsc = ( &wrkhd << 18 ) | 052;
	wrkscr = ( &wrkpos << 18 ) | 045;
	wrkrefr = ( work ) << 18 ;
	wrkpos = wrkrefr;

	/* walk on tree */

	walk( i );
	while( ( c = huf.rd() ) >= 0 ) putenc( encd[ c ] );
/* end of encode */ }



cleanb( table ){

	auto i;

	table++; /*compiler bug */
	table[ 2 ] = i = getvec( 320 );  /* the record buffer */
	table[ 1 ] = ( table  << 18 ) | 052 ; /* sc tally */
	table[ 3 ] = 0;
	table[ 4 ] = ( i << 18 ) | 040; /* the tally itself */
	table[ 5 ] = ( ( i + 320 ) << 18 ) | 040 ; /* the overflow tally */
	table[ 0 ] = table[ 5 ] + 1; /* current tally is exausted */
/* end of cleanb */ }


huffgen( table ){

	auto i, leaves, j, k, l, hd;
	extrn in.des, wd1;

	for( i = 511; i >= 0; --i ) if( table[ i ] > 01000 ) break;

	leaves = getvec( i );
	for( j =0; j <= i; ++j ){
		k = leaves[j] = getvec( 1 );
		k[ 0] = 0;
		k[ 1] = table[ j ] & 0777;
		table[ j ] =>> 9; }

	for( j =i; j>0; j ){
		hd = getvec(1);
		hd[0] = leaves[ j-1 ] ;
		hd[1] = leaves[ j ] ;
		leaves[ j-1 ] = hd;
		table[ j-1 ] =+ table[ j ];
		--j;

		for( k= j; k > 0; --k )      /* bubble */
			if( table[ k ] > table[ k-1 ] ){
				l = table[ k ];
				table[ k ] = table[ k-1 ];
				table[ k-1 ] = l;

				l = leaves[ k ];
				leaves[ k ] = leaves[ k-1 ];
				leaves[ k-1 ] = l ; }
			else  break;

	/* end of for */ }

	/* k is the head of tree */

	wd1 =| (table[0])<<18; /* size in llinks */
	wd1 =| ( in.des[4] &0200000)<<1; /* file mode */
	for( k=0; k<=7; ++k)chaput(0); /* skip two words */

	outtb( 0, hd ); /*        print table in output file */
	rlsevec( leaves, i );
	return( hd );
/* end of huffgen */ }




	/* externals */
huf.rd;
huf.rew;
huf.opn;
huf.wr;  /* these words are for switchin b/i/o &ran/i/o  */
in.tab [];
	in.ptr;
	in.tal;
	in.rec;
	in.sk;
	in.refr;
	in.of;
	in.tot;
	in.atual;
	in.opts[ 3 ] 0400000000000, 1, 1, 1;
	in.des [ 4 ] ;

outtab [];
	out.ptr;
	out.tal;
	outrec;
	out.sk;
	out.refr;
	out.of;
	out.max;
	out.opts[ 3 ] 0600000000001, 1, 1, 1;
	out.des [ 4 ];

biting 1 ; 

work[ 84 ];
	wrksc;
	wrkscr;
	wrkpos;
	wrkhd;
	wrkhsc;
	wrkrefr;

encd[ 512 ];
wd1;

/* end of externals */
