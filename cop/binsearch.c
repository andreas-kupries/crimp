/*
 * binsearch,c --
 *
 *	Template for a binary search procedure on arbitrary data types.
 *
 * Copyright (c) 2011 by Kevin B. Kenny.
 *
 * See the file "license.terms" for information on usage and redistribution of
 * this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 *-----------------------------------------------------------------------------
 */

/* 
 * This file is intended to be included in a larger program, and
 * specialized for a given data type. Prior to including it, the
 * program must have the definitions:
 *
 *	#define ITYPENAME grey8
 *	#define ITYPE unsigned char
 *	#include <stdlib.h>
 */

/*
 *
 *-----------------------------------------------------------------------------
 *
 * crimp_binarysearch_grey8, etc.
 * Binary search routine.  Parametrized by:
 *	ITYPENAME: Name of the type as postpended to a C identifier,
 *		  e,g,, grey8, grey16, grey32, float
 *	ITYPE: C data type corresponding to ITYPENAME (e.g., unsigned char,
 *	      unsigned short, unsigned int32_t, float)
 *
 * Results:
 *
 *	The generated routine searches a sorted array of type ITYPE for
 *	an object of the same type. The array is of length 'size', The
 *	return value is the largest index of an element <= needle, or
 *	-1 if all elements are greater than needle.
 *
 *-----------------------------------------------------------------------------
 */

/* 
 * The double substitution in FNAME/FNAME2 allows concatenation of
 * substituted parameters.
 */
#define FNAME2(name, type) name ## _ ## type
#define FNAME(name, type) FNAME2(name,type)

size_t
FNAME(crimp_binarysearch,ITYPENAME) (
    const ITYPE* haystack,	/* Array to search */
    size_t size,		/* Number of elements in the array */
    ITYPE needle		/* Value to search for */
) {

#undef FNAME
#undef FNAME2

    size_t l, u, m;		/* Lower bound (inclusive), upper bound
				 * inclusive) and midpoint (rounded up)
				 * of the range where the target element is
				 * found */

    /* Handle the edge case of 'not found' */

    if (size == 0 || needle < *haystack) {
	return -1;
    }

    l = 0;
    u = size-1;
    while (l < u) {

	/*
	 * Invariant for this loop:
	 *	needle >= haystack[l]; needle < haystack[u+1] or u = size
	 * Find the midpoint of [u,l], rounded up, and compare against it.
	 * Adjust to maintain the invariant. (u-l) shrinks by a factor
	 * of two at each step, guaranteeing convergence.
	 */

	m = (l + u + 1) / 2;
	if (needle >= haystack[m]) {
	    l = m;
	} else {
	    u = m-1;
	}
    }

    /*
     * l==u. needle >= haystack[l], but either needle < haystack(l+1)
     * or (l+1) == size. We have the unique element.
     */

    return l;

#undef Z

}
