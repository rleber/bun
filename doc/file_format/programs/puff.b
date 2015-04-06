/*
!b cmdlib/s/puff  cmdlib/puff  n
*/
main(){
		/*  decoding of huffman files **********/

	auto rec[ 30 ], freq[ 10 ], i, j , nchars;
	extrn in.opts, in.des, in.tot, in.atual, in.tab, in.ptr, in.refr, in.sk, in.tal, in.of;
	extrn out.opts, out.des, outtab, out.ptr, out.refr, out.max, outrec;
	extrn wd1, out.sk, treetop, in.rec,huf.wr, chaput, putcha;

	reread();
	getstr( REC );
	i = getarg( freq, rec, 0 );
	i = getarg( freq, rec, i, " *t;" );
	while( nullstr(freq)){
		putstr("input file name?");
		getstr( freq );
		}
	acc.fil( freq, in.opts, in.des );
	cleanb( in.tab );
	in.tot = 1; /* provisional value */
	for( j=0; j<=7; ++j)chaget(); /* skip 2 words */
	if( in.rec[ 0 ] != 'huff' ){
		printf( "*n File %s not encoded*n", freq);
		exit(); }
	wd1 = in.rec[1]; /* size, rand, this size */
	i =getarg( freq, rec, i );
	if( nullstr(freq)){
		printf("output file name?");
		getstr(freq);
		}
	if( wd1 < 0 ){
		huf.wr = putcha;
		nchars = wd1>>18 & 0377777; /* it is in chars */
		openw( 3, freq, nchars/1100 +1); /* size is a guess */
		}
	else	{
		huf.wr = chaput;
		nchars =(wd1 >> 18 ) ;
		out.opts[0] =( out.opts[0] & -2) | (( wd1 >> 17) & 1 );
		out.opts[1] =nchars/1280 ;
		acc.fil( freq, out.opts, out.des);
		out.max =(out.des[4] & 07777 ) *
			( ( out.des[4] & 0400000 ) == 0 ? 60: 5 );
		cleanb(outtab);
		out.ptr =out.refr; }
	in.tot = wd1 & 07777;
	intb( chaget(), &treetop ); /* build table */
	decode( nchars );
	if( wd1 > 0 ) writeb(); /* flushing buffer */
	if( ( in.des[ 4 ] & 040000 ) != 0 ) retfil( in.des );
	if( wd1 > 0 ) if( ( out.des[ 4 ] & 040000 ) != 0 ) retfil( out.des );
	exit();
/* end of main */ }
decode( nchars ){

	auto head, i;
	extrn treetop;

	while( nchars--){
		head = treetop;
		while( *head )head= head[ bitget() ];
		huf.wr( head[ 1 ] ); }
/* end of decode */ }

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

bitget(){
	extrn bitong ;
	auto c;

	if( ( bitong & 0400 ) == 0 ){
		if( (bitong = chaget() ) < 0 ) return(-1);
		bitong = (bitong << 27 ) | 0777 ; }
	c = bitong >> 35;
	bitong =<< 1;
	return( c ) ;
/* end of bitget */ }



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



intb( c, last ){

	last = *last = getvec( 1 );
	if( c-- ){
		intb( c, last );
		intb( chaget(), last+1 ); }
	else {
		last[ 0] = 0;
		last[ 1] = chaget() ; }
/* end of intb */ }







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

biting 1 ; bitong;

wd1;
treetop;

/* end of externals */
