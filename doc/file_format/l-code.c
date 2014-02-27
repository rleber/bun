/*
 * Test for the presence of an H* file
 * 1) Random
 * 2) First available space block is sector 1
 * 3) Next catalogue block is within the file
 * 4) The link word in the available space block is valid
 * 5) The first catalogue block checksums correctly
 * 6) The first available space lock checksums correctly
 */
hstr_t() {
	auto p;
	extrn buffer, is_rand, sectors;

	if (!is_rand || 1 != (HC_AVL[buffer] >> 18) ||
	    HC_NEXT[buffer] & DL >= sectors ||
	    0 != HA_NEXT[buffer+SECSIZE] & DU ||
	    HA_NEXT[buffer+SECSIZE] & DL >= sectors ||
	    chcksm(buffer, HC_CKSM, 1) != HC_CKSM[buffer] ||
	    chcksm(buffer+SECSIZE, HA_CKSM, 1) != HA_CKSM[buffer+SECSIZE])
		return(0);

	/*
	 * we have passed the 6 tests, now scan the first catalog block
	 * and check that the module types are valid (0, 1, 2 or 3),
	 * an that eack module lies between sector 2 and the end of the file
	 */
	for (p = &HC_FDESC[buffer]; p <= &buffer[HC_CKSM-HC_DSIZE];
	     p += HC_DSIZE) {
		if (3 < HC_DTYPE[p] >> 30 ||
		    HC_DLOC[p] & DL + (HC_DLEN[p] >> 18) & 07777 > sectors ||
		    2 > HC_DLOC[p] & DL && HC_DNAME[p])
			return(0);
	}
	return(1);
}
