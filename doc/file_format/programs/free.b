/*
 * I found the source to encode/decode freeze files!  -IAN!
 * From rftessner free.b
 */

#ttldat 160582  
#Copyright (c) 1982 by the University of Waterloo   
/*  
!b rftessner/b/free.b   




Format of a freeze file:


	Words 0-4 contain general info on the file:
		0 - # of words in the file (including directories)
		1 - # of frozen files 
		2 and 3 - date of last update in ascii chars  
		4 - time of last update as returned from drl TIME_
	Then follow a series of 10 word descriptors, one for each frozen file: 
		0 and 1 - name in ascii chars 
		2 and 3 - date of last update 
		4 - time of last update (as before)   
		5 - 'asc ' always 
		6 - # 64 word blocks occupied by frozen file  
		7 - starting word of the frozen file  
		8 - # words of the frozen file
		9 - -1 always 


	The freezing is done one line at a time, with the number of characters 
	in each line installed in bits 8-14 of the first frozen word of that   
	line (the start of every line starts a new word - any excess bit   
	space is zero) 


*/  
%b/manif/.bset  
%b/manif/drls   




.optab[]{   
	"Table",		PLUS_KWD | DASH_KWD, 
	"Clear",		PLUS_KWD | DASH_KWD, 
	"Delete",		SVAL_KWD,   
	"Rename",		SVAL_KWD,   
	"Update",		SVAL_KWD,   
	"Print",		SVAL_KWD,
	"Extract",		SVAL_KWD,  
	"RePlace",		SVAL_KWD,  
    "Append",       SVAL_KWD,   
    "INclude",      SVAL_KWD,   
	-1 
};  




/*  
 * optab manifests  
 */ 
OS_FILE    = 0; 
OF_TABLE   = 1; 
OF_CLEAR   = 2; 
OS_DELETE  = 3; 
OS_RENAME  = 4; 
OS_UPDATE  = 5; 
OS_PRINT   = 6; 
OS_EXTRACT = 7; 
OS_REPLACE = 8; 
OS_APPEND  = 9; 
OS_INCLUDE = 10;




/*  
 * manifests
 */ 
LLINK    = 320;		/* number of words in a llink */   
SECTOR   = 64;		/* number of words in a sector */   
LOTS     = -1>>1;	/* a big number */
HALF     = 18;		/* half word shift factor */
DL       = 0777777;	/* low half word mask */
WORKVEC  = 40;		/* a place to put strings */
NAMEMAX  = 8;		/* maximum length of a freeze name */
STDOUT   = 1;		/* standard output unit */   
TTYOUT   = -4;		/* terminal output */   
LINELEN  = 64;		/* maximum input line length */ 
ASC_CHAR = 0177;	/* mask for 1 ascii char */
PERMFILE = 1<<15;	/* mask for perm file */  




/*  
 * shift and time manifests 
 */ 
SH_INCR  = 7;		/* shift increment */
SH_LEN   = 21;		/* shift factor for installing length */
SH_INIT  = 14;		/* initial shift factor */  
SH_START = 28;		/* start shift factor for new word */   
TIME_SUM = 1620000;	/* additive offset for converting time */   
TIME_DIV = 3840000;	/* for converting ticks to secs */  
TIME_D1  = 2;		/* first date element of time_v */   
TIME_D2  = 3;		/* second date element */
TIME_T   = 1;		/* time element */   




/*  
 * directory manifests  
 */ 
DIRC_WORDS   = 0;		/* # words in freeze file */ 
DIRC_FILES   = 1;		/* # frozen files */ 
DIRC_DATE    = 2;		/* first half of date (two words) */ 
DIRC_TIME    = 4;		/* time of last update */
D_EXPAND     = * 10 + 5;	/* directory size given # files */ 
D_INCR       = 10;		/* directory element increment */   
D_BEGIN      = 5;		/* beginning of directory elements */
D_NAME1      = 0;		/* name of element (frozen file) */  
D_NAME2      = 1;   
D_DATE1      = 2;		/* date of last update */
D_DATE2      = 3;   
D_TIME       = 4;		/* time of last update */
D_ASCII      = 5;		/* file type - always 'asc ' */  
D_BLOCKS     = 6;		/* # 64 word blocks of frozen file */
D_START      = 7;		/* start word of frozen file */  
D_WORDS      = 8;		/* # of words in frozen file */  
D_FLAG       = 9;		/* end of entry flag - always -1 */  








/*  
 * externals
 */ 
apvec;			/* vector of files to freeze */
buffin;			/* input buffer */
buffout;		/* output buffer */   
dirc;			/* directory of given freeze file */
frz_unit;		/* unit number of given freeze file */   
inptr;			/* pointer to current word of buffin */
in_sect;		/* current input sector for read */   
ndirc_ptr;		/* pointer to offset in newdirc */  
newdirc;		/* directory for the updated freeze file */   
nfroz;			/* number of files already frozen */   
outptr;			/* pointer to current word in buffout */  
out_sect;		/* current output sector for buffout */  
outword;		/* current word of new freeze file */ 
t_frz;			/* unit number of temp freeze image */ 
time_v[3];		/* date - time info for the updated directory */
xvec;			/* vector of frozen images to extract or print */   






.   


main( argc, argv ){ 


	extrn .argtype, apvec, buffin, buffout, dirc, frz_unit, ndirc_ptr; 
	extrn newdirc, nfroz, out_sect, outptr, outword, t_frz, time_v, xvec;  
	extrn delopt, append, replace, printopt, extopt;   


	auto i, pos, temp, l, arg,		/* handy indexing and temps */ 
		name[2], oldname[2], newname[2],		/* for freeze names */  
		dircsz,						/* size of the directory */  
		dmax,						/* maximum directory word */   
		frz_lib,					/* the name of the freeze file */
		nfiles,						/* number of files frozen */ 
		writ, table, clear, d.or.r,		/* flags */  
		file_args,					/* number of files to freeze */
		fileptr,					/* pointer to arg as file if only one unflagged arg */   
		included,					/* flag for include options */  
		here,						/* used to scan include string */  
		strlen, 					/* length of included string */  
		holdstr[WORKVEC],			/* temp place for one file name from include list */  
		nstrings; 




	nfiles = clear = writ = table = file_args = frz_lib = d.or.r = 0;  
	included = fileptr = strlen = nstrings = 0;


	/* 
	 * first pass - look for conflicts, library
	 */
	for( i=1; i < argc; ++i )  switch( argv[i] >> HALF ){  


	  case OF_TABLE:   
		if( table ) error( "FREEZE: '(+|-)Table' was specified twice*n" );
		table = (.argtype[i] == '+')? 1: -1;  
		next; 


	  case OF_CLEAR:   

		if( clear ) error( "FREEZE: '(+|-)Clear' was specified twice*n" );
		clear = (.argtype[i] == '+')? 1: -1;  
		if( clear > 0 ) ++writ;   
		next; 


	  case OS_APPEND:  
	  case OS_REPLACE: 
		++file_args;  
		++writ;   
		next; 


	  case OS_DELETE:  
	  case OS_RENAME:  
		++d.or.r; 
		++writ;   
		next; 


	  case OS_UPDATE:  
		if( frz_lib ) error( "FREEZE: two freeze files were specified*n" );   
		frz_lib = argv[i];
		next; 


	  case OS_FILE:
		++nstrings;   
		fileptr = argv[i];
		next; 


	  case OS_INCLUDE: 
		++included;   
		next; 


	  case OS_PRINT:   
	  case OS_EXTRACT: 
		next; 


	  default: 
		error( "FREEZE: '%s' is an unrecognized option*n", argv[i] ); 
	}  




	/* 
	 * search for freeze file if none found yet
	 */
	if( !frz_lib ) {   
		if ( nstrings > 1 )   
			error( "FREEZE: unable to determine freezefile, use 'Update=' or freezefile*n" );
		else if ( nstrings < 1 )  
			error( "FREEZE: no freeze file specified, use 'Update=' or freezefile*n" );  
		else {
			frz_lib = fileptr;   
			nstrings = -1;   
		} 
	}  
	else   ile 		file_args += nstri

		file_args += nstrings;


	/* 
	 * error checking  
	 */
	if( clear > 0 && d.or.r )  
		error( "FREEZE: '+Clear' and 'Delete=' or 'Rename=' is an invalid*
			* option combination*n" );   
	if ( clear > 0 )   
		if ( ( file_args < 1 ) && ( !included ) ) 
			error( "FREEZE: no file to be frozen for new freeze file*n" );   
	if( ( included > 0 ) || ( file_args > 0 ) ) ++writ;


	/* 
	 * set up working directories  
	 */
	buffin = getvec( WORKVEC );
	get_time();
	frz_unit = open( frz_lib, writ? "wbou": "rbou" );  
	temp = fildes( frz_unit ); 
	if( !(temp & PERMFILE) )   
		printf( TTYOUT, "FREEZE: warning: '%s' is a temporary file*n", frz_lib ); 


	if( clear > 0) nfroz = dirc = 0;   
	else{  
		read( frz_unit, buffin, 0, 5 );   
		if( buffin[ DIRC_WORDS ] & ~07777777 ||   
			 buffin[ DIRC_FILES ] & ~07777 ) 
			error( "FREEZE: '%s' is not a freeze file*n", frz_lib ); 
		dirc = getvec( dircsz = buffin[ DIRC_FILES ] D_EXPAND );  
		read( frz_unit, dirc, 0, dircsz );
		if( !isfreeze( dircsz ) ) 
			error( "FREEZE: '%s' is not a freeze file*n", frz_lib ); 
		nfroz = dirc[ DIRC_FILES ];   
	}  


	xvec = getvec( 0 );
	apvec = getvec( 0 );   
	xvec[0] = apvec[0] = 0;




	/* 
	 * main option pass
	 */
	for( i=1; i < argc; ++i ) switch( (arg = argv[i]) >> HALF ){   


	  case OF_CLEAR:   
	  case OF_TABLE:   
	  case OS_UPDATE:  
		next; 


	  case OS_DELETE:  
		repopt( arg, delopt );
		next; 
	  case OS_APPEND:  
		repopt( arg, append );
		next; 


	  case OS_REPLACE: 
		repopt( arg, replace );   
		next; 




	  case OS_PRINT:   
		repopt( arg, printopt );  
		next; 


	  case OS_EXTRACT: 
		repopt( arg, extopt );
		next; 


	  case OS_RENAME:  
		if( length( arg ) > NAMEMAX * 2 + 1 ) 
			error( "FREEZE: '%s' is an unrecognized argument*n", arg );  
		zero( buffin, WORKVEC );  
		pos = scan( buffin, arg, 0, "," );
		if( (l = length( buffin )) > NAMEMAX )
			error( "FREEZE: '%s' is an unrecognized argument*n", buffin );   
		movelr( oldname, 0, buffin, 0, NAMEMAX, l );  
		zero( buffin, WORKVEC );  
		scan( buffin, arg, pos, "," );
		if( (l = length( buffin )) > NAMEMAX )
			error( "FREEZE: '%s' is an unrecognized argument*n", buffin );   
		movelr( newname, 0, buffin, 0, NAMEMAX, l );  
		if( !(temp = search( oldname )) ) 
			error( "FREEZE: unable to rename: '%s' is not in the freeze file*n", 
				 oldname ); 
		if( search( newname ) )   
			error( "FREEZE: '%s' is already in the freeze file*n", newname );
		dirc[ temp ] = newname[0];
		dirc[ temp + D_NAME2 ] = newname[1];  
		next; 


	  case OS_FILE:
		if( nstrings < 0 ) next;  
		apvec = addvec( apvec );  
		apvec[ ++apvec[0] ] = getvec( length( arg ) / 4 + 1 );
		concat( apvec[ apvec[0] ], arg ); 
		getname( arg, buffin, 1 );
		delete( buffin ); 
		next; 


	  case OS_INCLUDE: 
		strlen = length( arg );   
		if ( strlen == 0 )
			error( "FREEZE: 'INclude' list is empty*n" );
		for ( here=0; here<strlen; here++ ) { 
			apvec = addvec( apvec ); 
			here = scan( holdstr, arg, here, "*t ", "," );   
			apvec[ ++apvec[0] ] = getvec( length( holdstr ) / 4 + 1 );   
			concat( apvec[ apvec[0] ], holdstr );
			getname( apvec[ apvec[0] ], buffin, 1 ); 
			delete( buffin );
		} 
		next; 


	  default: 
		error( "FREEZE: Aaarrg! A bug!!! %s*n", arg );
	}  
	rlsevec( buffin, WORKVEC );




	/* 
	 * if only read then do a list/table   
	 */
	if( !writ && argc == 3 && table > 0 ) puttable();  
	if( argc == 2 ) putlist(); 




	buffin = getvec( LLINK );  
	if( writ || file_args > 0 ){   


		/*
		 * get space for a new directory and initiate pointers
		 */   
		nfiles = nfroz + apvec[0];
		newdirc = getvec( outword = dmax = nfiles D_EXPAND ); 
		buffout = getvec( LLINK );
		outptr = outword % SECTOR;
		out_sect = outword / SECTOR;  
		ndirc_ptr = D_BEGIN;  
		t_frz = open( "fc**fz", "wbout" );
	   
		/*
		 * copy already frozen files to a temp freeze file
		 */   
		for( i=D_BEGIN; dirc && i < dirc[1] D_EXPAND; i+=D_INCR ) 
			if( dirc[i] != 0 ) copy_old( i );
	   
		/*
		 * freeze the new files   
		 */   
		for( i=1; i <= apvec[0]; ++i ) freeze(i); 
	   
		/*
		 * flush the output buffer
		 */   
		if( outptr != 0 ) flush_out();
	   
	   
		/*
		 * write the directory in, with date and time etc.
		 */   
		newdirc[ DIRC_WORDS ] = outword;  
		newdirc[ DIRC_FILES ] = nfroz + apvec[0]; 
		newdirc[ D_DATE1 ] = time_v[ TIME_D1 ];   
		newdirc[ D_DATE2 ] = time_v[ TIME_D2 ];   
		newdirc[ DIRC_TIME ] = time_v[ TIME_T ];  
		for( i=0; i < dmax/LLINK*5; i+=5 )

			write( t_frz, (newdirc + i*SECTOR), i, LLINK );  
		if( temp = dmax % LLINK ){
			read( t_frz, buffout, i, LLINK );
			copy( buffout, (newdirc + i * SECTOR), temp - 1 );   
			write( t_frz, buffout, i, LLINK );   
		} 
	   
		/*
		 * copy the  temp to the perm freeze file 
		 */   
		nobrks( LOTS );   
		for( i=0; i < newdirc[0] / LLINK + 1; ++i ){  
			read( t_frz, buffin, i * 5, LLINK ); 
			write( frz_unit, buffin, i * 5, LLINK ); 
		} 
		nobrks( 0 );  
		close( t_frz );   
		close( frz_unit );
		if( dirc ) rlsevec( dirc, dircsz );   
		rlsevec( newdirc, dmax ); 
		if( nfiles == 0 ) 
			printf( TTYOUT, "FREEZE: '%s' is no longer a freeze file*n", 
				frz_lib );  
	}  


	/* 
	 * print or extract files  
	 */
	frz_unit = open( frz_lib, "rbou" );
	read( frz_unit, buffin, 0, 2 );
	dirc = getvec( temp = buffin[ DIRC_FILES ] D_EXPAND ); 
	read( frz_unit, dirc, 0, temp );   
	for( i=1; i <= xvec[0]; ++i ) extract( xvec[i] );  






	/* 
	 * put a table 
	 */
	if( table > 0 ) puttable();
}   
.   


/*  
 * write the output buffer to the temp freeze image 
 */ 
flush_out(){
	extrn buffout, out_sect, outptr, t_frz;


	write( t_frz, buffout, out_sect, LLINK );  
	zero( buffout, LLINK );
	outptr = 0;
	out_sect += 5; 
}   




/*  
 * get another llink of input from the old freeze file  
 */ 
get(){  
	extrn buffin, frz_unit, in_sect, inptr;


	read( frz_unit, buffin, in_sect, LLINK );  
	inptr = 0; 
	in_sect += 5;  
}   




/*  
 * deletes an element from the old freeze file  
 * it zeros the name field in the old directory (dirc)  
 */ 
delete( name ){ 
	extrn dirc, nfroz; 
	auto i, offset;


	offset = D_BEGIN;  
	for( i=1; i <= dirc[ DIRC_FILES ]; ++i ){  
		if( name[0] == dirc[ offset ] && name[1] == dirc[ offset+1 ] ){   
			dirc[ offset ] = dirc[ offset+1 ] = 0;   
			--nfroz; 
			return( offset );
		} 
		offset += D_INCR; 
	}  
	return(0); 
}   




/*  
 * process repititious options (separated by commas)
 * calls the appropriate function to do the job 
 */ 
repopt( arg, func ){
	auto l, pos, offset, element[ WORKVEC ];   
	auto fname[3]; 
	extrn dirc;


	l = length( arg ); 
	if( l == 0 )    a l		error( "FREEZE: Please specify argumen


.....D$.
rftessner...

		error( "FREEZE: Please specify arguments after '='*n" );  
	for( pos=0; pos < l; ){
		zero( element, WORKVEC ); 
		pos = scan( element, arg, pos, "," ); 
		if (equal (element, "**")) {  
			offset = D_BEGIN;
			for (l = 1; l <= dirc[DIRC_FILES]; l++) {
				print (fname, "%8a", &dirc[offset]);
				func (fname);   
				offset += D_INCR;   
			}
		} 
		else  
			func( element ); 
	}  
}   




/*  
 * set up the print option -> add an element to the extract vector  
 */ 
printopt( name ){   
	extrn xvec;


	xvec = addvec( xvec ); 
	xvec[ ++xvec[0] ] = getvec( length( name ) / 4 + 1 ) | 1 << HALF;  
	concat( xvec[ xvec[0] ], name );   
}   




/*  
 * set up the extract option - same as printopt almost  
 *  
 */ 
extopt( name ){ 
	extrn xvec;


	xvec = addvec( xvec ); 
	xvec[ ++xvec[0] ] = getvec( length( name ) / 4 + 1 );  
	concat( xvec[ xvec[0] ], name );   
}   




/*  
 * append an element - do no checks now cause if there's a duplicate
 * it will be found when freeze() gets it   
 */ 
append( name ){ 
	extrn apvec;   


	apvec = addvec( apvec );   i < 	apvec[ ++apvec[0] ]

	apvec[ ++apvec[0] ] = getvec( length( name ) / 4 + 1 );
	concat( apvec[ apvec[0] ], name ); 
}   






/*  
 * replace an element -> it must be in the freeze file or else  
 */ 
replace( name ){
	extrn apvec;   
	auto fname[2]; 


	apvec = addvec( apvec );   
	apvec[ ++apvec[0] ] = getvec( length( name ) / 4 + 1 );
	concat( apvec[ apvec[0] ], name ); 
	getname( name, fname, 1 ); 
	if( !delete( fname ) ) 
		error( "FREEZE: inable to replace '%8s'*n", fname );  
}   




/*  
 * delete something from the freeze file
 */ 
delopt( name ){ 
	auto fname[2]; 


	getname( name, fname, 0 ); 
	if( !delete( fname ) ) 
		printf( TTYOUT, "FREEZE: '%8s' is not in the freeze file*n", fname ); 
}   






/*  
 * looks for an element in the old freeze file  
 * returns offset into dirc if found, else zero 
 */ 
search( name ){ 
	extrn dirc;
	auto i, offset;


	offset = D_BEGIN;  
	for( i=1; i <= dirc[1]; ++i ){ 
		if( name[0] == dirc[ offset ] && name[1] == dirc[ offset+1 ] )
			return( offset );
		offset += D_INCR; 
	}  
	return(0); 
}   






/*  
 * extracts the freezename from the filename
 */ 
getname( path, frzname, in ){   
	auto pos, l, temp[ WORKVEC ];  


	zero( temp, WORKVEC ); 
	l = length( path );
	pos = scan( temp, path, 0, "", "<>:;" );   
	if( pos >= l ){	/* no redirection */   
		if( any( '/', temp ) >= 0 ){	/* its a pathname only */
			for( pos=0; pos < l; ) pos = scan( temp, path, pos, "/" );   
			l = length( temp );  
			movelr( frzname, 0, temp, 0, NAMEMAX, l );   
			return;  
		} 
		/* its just a freeze file */  
		if( (l=length( temp )) > NAMEMAX )
			error( "FREEZE: '%s' is an invalid freeze name*n", temp );   
		movelr( frzname, 0, path, 0, NAMEMAX, l );
		return;   
	}  
	/* redirection */  
	if( (l=length( temp )) > NAMEMAX ) 
		error( "FREEZE: '%s' is an invalid freeze name*n", temp );
	if( (in > 0 && char( path, pos ) == '>')   
		|| (in < 0 && char( path, pos ) == '<') ) 
		error( "FREEZE: bad redirection to/from freezename*n" );  
	movelr( frzname, 0, temp, 0, NAMEMAX, l ); 
	zero( temp, 2 );   
	scan( temp, path, ++pos, "" ); 
	concat( path, temp );  
}   






/*  
 * output a table of the elements and die   
 */ 
puttable(){ 
	extrn dirc;
	auto min, i, offset;   


	min = (dirc[ DIRC_TIME ] + TIME_SUM) / TIME_DIV;	/* # of minutes */
	printf( STDOUT, "%8a %2d:%2,0d last updated*n*n",  
		&dirc[ DIRC_DATE ], min/60, min%60 ); 
	printf( STDOUT, "name      creation date   type  blocks  words*n" );   
	offset = D_BEGIN;  
	for( i=1  ; i <= dirc[ DIRC_FILES ]; ++i ){
		min = (dirc[ offset+D_TIME ] + TIME_SUM) / TIME_DIV;  
		printf( STDOUT, "%8a %8a   %2d:%2,0d %c   %3d   %6d*n",   
			&dirc[ offset ], &dirc[ offset+D_DATE1 ], min/60, min%60,
			dirc[ offset+D_ASCII ], dirc[ offset+D_BLOCKS ], 
			dirc[ offset+D_WORDS ] );
		offset += D_INCR; 
	}  
	i = 1 + dirc[ DIRC_WORDS ] / LLINK;
	printf( STDOUT, "*n%d file%s frozen in %d llink%s*n",  
		dirc[ DIRC_FILES ], dirc[ DIRC_FILES ] == 1? "": "s", 
		i, i == 1? "": "s" ); 
	exit();
}   




/*  
 * output a terse list of the elements  
 */ 
putlist(){  
	extrn dirc;
	auto offset, i;


	offset = D_BEGIN;  
	for( i=1; i <= dirc[ DIRC_FILES ]; ++i ){  
		printf( STDOUT, "%8a ", &dirc[ offset ] );
		if( i % 8 == 0 ) putc( STDOUT, '*n' );
		offset += D_INCR; 
	}  
	i = 1 + dirc[ DIRC_WORDS ] / LLINK;
	printf( STDOUT, "*n%d file%s frozen in %d llink%s*n",  
		dirc[ DIRC_FILES ], dirc[ DIRC_FILES ] == 1? "": "s", 
		i, i == 1? "": "s" ); 
	exit();
}   




/*  
 * get the date and time for the updating   
 */ 
get_time(){ 
	extrn time_v, drl.q;   


	drl.drl( TIME_, &time_v[2] << HALF );  
	time_v[ TIME_T ] = drl.q;  
}   




/*  
 * search for a freeze name in the new directory
 * return zero if not found else 1  
 */ 
newsearch( name ){  
	extrn newdirc, ndirc_ptr;  
	auto offset;   


	for( offset=D_BEGIN; offset < ndirc_ptr; offset += D_INCR )
		if( newdirc[ offset ] == name[0] && newdirc[ offset+1 ] == name[1] )  
			return( 1 ); 
	return( 0 );   
}   




/*  
 * see if the supposed freeze file is a freeze file 
 */ 
isfreeze( dircmax ){
	extrn dirc;
	auto p, i; 


	p = 12;
	for( i=1; i < dirc[ DIRC_FILES ]; ++i ){   
		if( dirc[p] + dirc[ p+1 ] != dirc[ p+10 ] || dirc[ p+2 ] != -1 )  
			return( 0 ); 
		p += 10;  
	}  
	if( dirc[p] + dirc[ p+1 ] != dirc[ DIRC_WORDS ] || dirc[ p+2 ] != -1   
		|| dirc[ 12 ] != dircmax )
		return( 0 );  
	return( 1 );   
}   
.   cts 



/*  
 * copies a file that is already frozen into the temp freeze image  
 * the new directory is updated 
 */ 
copy_old( info ){   
	extrn dirc, newdirc, buffin, buffout, outptr, out_sect, outword;   
	extrn inptr, in_sect, ndirc_ptr;   
	auto maxword;  


	/* 
	 * set the new directory   
	 */
	copy(newdirc+ndirc_ptr, dirc+info, 10);
	newdirc[ ndirc_ptr + D_START ] = outword;  


	/* 
	 * copy it all over
	 */
	maxword = outword + newdirc[ ndirc_ptr + D_WORDS ];
	in_sect = dirc[ info + D_START ] / SECTOR; 
	get(); 
	inptr = dirc[ info + D_START ] % SECTOR;   
	while( outword < maxword ){
		if( outptr >= LLINK ) flush_out();
		if( inptr >= LLINK ) get();   
		while( inptr < LLINK && outptr < LLINK && outword < maxword ){
			buffout[ outptr++ ] = buffin[ inptr++ ]; 
			outword++;   
		} 
	}  
	if( outptr >= LLINK ) flush_out(); 
	ndirc_ptr += D_INCR;   
}   
.   


/*  
 * freeze a file, updating the directory
 */ 
freeze( current ){  
	extrn apvec, buffin, buffout, ndirc_ptr, newdirc, outptr;  
	extrn outword, time_v; 
	auto in, name[10], packvec, start, stop, unit; 

e   	getname( apvec[ current ], name, 1 

	getname( apvec[ current ], name, 1 );  
	if( newsearch( name ) )
		error( "FREEZE: '%s' is already in the freeze file*n", name );
	start = outword;		/* for the directory */  
	packvec = buffin + 100;	/* its available */
	unit = open( apvec[ current ], "r" );  


	/* 
	 * freeze the file one line at a time  
	 */
	zero( buffin, LINELEN );   
	while( getstr( buffin, LINELEN * 4 ) ){
		stop = outword + pack( packvec, current );
		in = 0;   
		while( outword < stop ){  
			if( outptr >= LLINK ) flush_out();   
			while( outptr < LLINK && outword < stop ){   
				buffout[ outptr++ ] = packvec[ in++ ];  
				++outword;  
			}
		} 
		if( outptr >= LLINK ) flush_out();
		zero( buffin, LINELEN );  
	}  
	close( unit ); 


	/* 
	 * update the directory
	 */
	newdirc[ ndirc_ptr++ ] = name[0];  
	newdirc[ ndirc_ptr++ ] = name[1];  
	newdirc[ ndirc_ptr++ ] = time_v[ TIME_D1 ];
	newdirc[ ndirc_ptr++ ] = time_v[ TIME_D2 ];
	newdirc[ ndirc_ptr++ ] = time_v[ TIME_T ]; 
	newdirc[ ndirc_ptr++ ] = 'asc ';   
	newdirc[ ndirc_ptr++ ] = (outword - start) / SECTOR;   
	newdirc[ ndirc_ptr++ ] = start;
	newdirc[ ndirc_ptr++ ] = outword - start;  
	newdirc[ ndirc_ptr++ ] = -1;   
}   




/*  
 * pack the input one line at a time
 */ 
pack( into, current ){  
	extrn apvec, buffin;   
	auto i, l, word, shift, c; 


	zero( into, LINELEN ); 
	word = 0;  
	l = length( buffin ) + 1;  
	into[0] = l << SH_LEN; 
	shift = SH_INIT;   
	for( i=0; i < l-1; ++i ){  
		into[ word ] |= ( (c=char( buffin, i )) << shift );   
		if( c > ASC_CHAR )
			error( "FREEZE: non-ascii input encountered in file '%s'*n", 
				apvec[ current ] ); 
		if( (shift -= SH_INCR) < 0 ){ 
			++word;  
			shift = SH_START;
		} 
	}  
	into[ word ] |= ('*r' << shift);   
	return( word + 1 );
}   
.   


/*  
 * unfreeze a file - does not die if given wrong file   
 */ 
extract( name ){
	extrn buffin, dirc, frz_unit, inptr, in_sect;  
	auto end, fzname[10], offset, unit, word;  


	printf (STDOUT, "Extracting: %s*n", name); 
	flush (STDOUT);
	getname( name, fzname, -1 );   
	if( !(offset = search( fzname )) ){
		printf( TTYOUT, "FREEZE: '%s' is not in the freeze file*n", fzname ); 
		return;   
	}  
	if( name >> HALF )	/* to the standard output */
		unit = STDOUT;
	else unit = open( n

	else unit = open( name & DL, "w" );
	word = dirc[ offset + D_START ];   
	end = word + dirc[ offset + D_WORDS ]; 
	in_sect = word / SECTOR;   
	get(); 
	inptr = word % SECTOR; 
	while( word < end ){   
		if( inptr >= LLINK ) get();   
		while( inptr < LLINK && word < end ){ 
			putword( unit, inptr++ );
			++word;  
		} 
	}  
	if( unit != STDOUT ) close( unit );
}   




/*  
 * thaw out one frozen word 
 */ 
putword( unit, i ){ 
	extrn buffin;  
	auto char, shift;  


	shift = SH_START;  
	while( shift >= 0 ){   
		char = (buffin[i] >> shift) & ASC_CHAR;   
		if( shift == SH_START && (buffin[i] >> (shift+1)) == 0 ){ 
			shift -= (SH_INCR * 2);  
			char = (buffin[i] >> shift) & ASC_CHAR;  
		} 
		if( char == 0 ) return;   
		if( char == '*r' ) putc( unit, '*n' );
		else putc( unit, char );  
		shift -= SH_INCR; 
	}  
}   
