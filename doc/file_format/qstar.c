/*
 * (c) Copyright 1992,1996 by Thinkage Ltd.
 *
 * Manifests for a H*'s and Q*'s
 */
SECSIZE = 64;		/* Size of a sector (in words) */
LLINK   = 320;		/* Size of a llink (in words) */
HC_FCAT = 0;		/* Seek address of first catalogue block */

/* Catalogue block structure */
HC_AVL = 0;			/* Seek ^ to first available space block (bits 0->17)
					 * First catalogue block only */
HC_NEXT = 0;		/* Seek ^ to next catalogue block (bits 18->35) */
					/* word at offset 1 is NOT used */
HC_FDESC = 2;		/* First H* data descriptor */
HC_CKSM = 63;		/* Checksum */
HC_SIZE = SECSIZE;	/* Size of structure */

/*
 * Data descriptor (catalogue struct)
 * Time stamp, and associated element fields are Thinkage extensions
 */
HC_DNAME = 0;		/* Element name (BCD) */
HC_DLOC  = 1;		/* Seek ^ to data (bits 18->35) */
HC_DLEN  = 1;		/* Data length (sectors) (bits 6->17) */
HC_DTYPE = 1;		/* Data type (bits 0->5) */
HC_DSYMT = 2;		/* Associated element (OVLD symbol element name) */
HC_DTIME = 3;		/* Time stamp (seconds since 1 Jan 1900) */
HC_DSIZE = 4;		/* Size of structure */

/* Available space block */
HA_NEXT = 0;		/* Seek ^ to next available space block (18-35)
					 * 0-17 are zero */
HA_FDESC = 1;		/* First available space descriptor
					 * (0-17) starting free sector, 18-15 count */
HA_CKSM = 63;		/* Checksum */
HA_SIZE = SECSIZE;	/* Size of an available space block */

/* Data block structure */
HD_DCHECK = 0;		/* Data checksum */
HD_RCHECK = 1;		/* Relocation data checksum */
HD_CCHECK = 2;		/* Checksum of this block */
HD_NAME = 3;		/* Element name (BCD) */
HD_ENTRY = 4;		/* Entry point (bits 0->17) */
HD_ORIGIN = 4;		/* Origin (bits 18->35) */
HD_RSIZE = 5;		/* Size of relocation data (sectors) (bits 0->17) */
HD_DSIZE = 5;		/* Size of data (sectors) (bits 18->35) */
HD_DCWS = 6;		/* Start of DCW list */
HD_SIZE = SECSIZE;	/* Size of structure */
