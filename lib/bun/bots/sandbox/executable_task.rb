#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

# Test to see if a file is a Honeywell "Q*" executable file

# C language code for tests, courtesy of Alan Bowler at Thinkage (www.thinkage.ca)

# /*
#  * (c) Copyright 1992,1996 by Thinkage Ltd.
#  *
#  * Manifests for a H*'s and Q*'s
#  */
# SECSIZE = 64;   /* Size of a sector (in words) */
# LLINK   = 320;    /* Size of a llink (in words) */
# HC_FCAT = 0;    /* Seek address of first catalogue block */

# /* Catalogue block structure */
# HC_AVL = 0;     /* Seek ^ to first available space block (bits 0->17)
#            * First catalogue block only */
# HC_NEXT = 0;    /* Seek ^ to next catalogue block (bits 18->35) */
#           /* word at offset 1 is NOT used */
# HC_FDESC = 2;   /* First H* data descriptor */
# HC_CKSM = 63;   /* Checksum */
# HC_SIZE = SECSIZE;  /* Size of structure */

# /*
#  * Data descriptor (catalogue struct)
#  * Time stamp, and associated element fields are Thinkage extensions
#  */
# HC_DNAME = 0;   /* Element name (BCD) */
# HC_DLOC  = 1;   /* Seek ^ to data (bits 18->35) */
# HC_DLEN  = 1;   /* Data length (sectors) (bits 6->17) */
# HC_DTYPE = 1;   /* Data type (bits 0->5) */
# HC_DSYMT = 2;   /* Associated element (OVLD symbol element name) */
# HC_DTIME = 3;   /* Time stamp (seconds since 1 Jan 1900) */
# HC_DSIZE = 4;   /* Size of structure */

# /* Available space block */
# HA_NEXT = 0;    /* Seek ^ to next available space block (18-35)
#            * 0-17 are zero */
# HA_FDESC = 1;   /* First available space descriptor
#            * (0-17) starting free sector, 18-15 count */
# HA_CKSM = 63;   /* Checksum */
# HA_SIZE = SECSIZE;  /* Size of an available space block */

# /* Data block structure */
# HD_DCHECK = 0;    /* Data checksum */
# HD_RCHECK = 1;    /* Relocation data checksum */
# HD_CCHECK = 2;    /* Checksum of this block */
# HD_NAME = 3;    /* Element name (BCD) */
# HD_ENTRY = 4;   /* Entry point (bits 0->17) */
# HD_ORIGIN = 4;    /* Origin (bits 18->35) */
# HD_RSIZE = 5;   /* Size of relocation data (sectors) (bits 0->17) */
# HD_DSIZE = 5;   /* Size of data (sectors) (bits 18->35) */
# HD_DCWS = 6;    /* Start of DCW list */
# HD_SIZE = SECSIZE;  /* Size of structure */
# /*
#  * Test for the presence of an H* file
#  * 1) Random
#  * 2) First available space block is sector 1
#  * 3) Next catalogue block is within the file
#  * 4) The link word in the available space block is valid
#  * 5) The first catalogue block checksums correctly
#  * 6) The first available space lock checksums correctly
#  */
# hstr_t() {
#   auto p;
#   extrn buffer, is_rand, sectors;

#   if (!is_rand || 1 != (HC_AVL[buffer] >> 18) ||
#       HC_NEXT[buffer] & DL >= sectors ||
#       0 != HA_NEXT[buffer+SECSIZE] & DU ||
#       HA_NEXT[buffer+SECSIZE] & DL >= sectors ||
#       chcksm(buffer, HC_CKSM, 1) != HC_CKSM[buffer] ||
#       chcksm(buffer+SECSIZE, HA_CKSM, 1) != HA_CKSM[buffer+SECSIZE])
#     return(0);

#   /*
#    * we have passed the 6 tests, now scan the first catalog block
#    * and check that the module types are valid (0, 1, 2 or 3),
#    * an that eack module lies between sector 2 and the end of the file
#    */
#   for (p = &HC_FDESC[buffer]; p <= &buffer[HC_CKSM-HC_DSIZE];
#        p += HC_DSIZE) {
#     if (3 < HC_DTYPE[p] >> 30 ||
#         HC_DLOC[p] & DL + (HC_DLEN[p] >> 18) & 07777 > sectors ||
#         2 > HC_DLOC[p] & DL && HC_DNAME[p])
#       return(0);
#   }
#   return(1);
# }

desc "executable", "Test if a file is a Honeywell Q* executable"
def executable(file)
  res = File::Unpacked.open(file) {|f| f.data.executable? }
  if res
    puts "#{file} is an executable"
    exit 0
  else
    puts "#{file} is not an executable"
    exit 1
  end
end
