/*
 *-----------------------------------------------------------------------------
 *
 * linearmaps.c --
 *
 *	Code to make all the piecewise linear mapping operations.
 *
 * Copyright (c) 2011 by Kevin B. Kenny
 *
 * See the file "license.terms" for information on usage and redistribution of
 * this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 *-----------------------------------------------------------------------------
 */

#include <tcl.h>
#include <stdlib.h>

/*
 * Make the four functions, crimp_binarysearch_TYPE1 and 
 * crimp_linearmap_TYPE1_TYPE2, where TYPE1 and TYPE2 are in the
 * set {grey8, grey16, grey32, float}.
 */

#define ITYPENAME grey8
#define ITYPE unsigned char

#include "binsearch.c"

#define OTYPENAME grey8
#define OTYPE unsigned char

#include "linearmap.c"

#undef OTYPENAME
#undef OTYPE

#define OTYPENAME grey16
#define OTYPE unsigned short

#include "linearmap.c"

#undef OTYPENAME
#undef OTYPE

#define OTYPENAME grey32
#define OTYPE unsigned int

#include "linearmap.c"

#undef OTYPENAME
#undef OTYPE

#define OTYPENAME float
#define OTYPE float

#include "linearmap.c"

#undef OTYPENAME
#undef OTYPE

#undef ITYPENAME
#undef ITYPE

#define ITYPENAME grey16
#define ITYPE unsigned short

#include "binsearch.c"

#define OTYPENAME grey8
#define OTYPE unsigned char

#include "linearmap.c"

#undef OTYPENAME
#undef OTYPE

#define OTYPENAME grey16
#define OTYPE unsigned short

#include "linearmap.c"

#undef OTYPENAME
#undef OTYPE

#define OTYPENAME grey32
#define OTYPE unsigned int

#include "linearmap.c"

#undef OTYPENAME
#undef OTYPE

#define OTYPENAME float
#define OTYPE float

#include "linearmap.c"

#undef OTYPENAME
#undef OTYPE

#undef ITYPENAME
#undef ITYPE

#define ITYPENAME grey32
#define ITYPE unsigned int

#include "binsearch.c"

#define OTYPENAME grey8
#define OTYPE unsigned char

#include "linearmap.c"

#undef OTYPENAME
#undef OTYPE

#define OTYPENAME grey16
#define OTYPE unsigned short

#include "linearmap.c"

#undef OTYPENAME
#undef OTYPE

#define OTYPENAME grey32
#define OTYPE unsigned int

#include "linearmap.c"

#undef OTYPENAME
#undef OTYPE

#define OTYPENAME float
#define OTYPE float

#include "linearmap.c"

#undef OTYPENAME
#undef OTYPE

#undef ITYPENAME
#undef ITYPE

#define ITYPENAME float
#define ITYPE float

#include "binsearch.c"

#define OTYPENAME grey8
#define OTYPE unsigned char

#include "linearmap.c"

#undef OTYPENAME
#undef OTYPE

#define OTYPENAME grey16
#define OTYPE unsigned short

#include "linearmap.c"

#undef OTYPENAME
#undef OTYPE

#define OTYPENAME grey32
#define OTYPE unsigned int

#include "linearmap.c"

#undef OTYPENAME
#undef OTYPE

#define OTYPENAME float
#define OTYPE float

#include "linearmap.c"

#undef OTYPENAME
#undef OTYPE

#undef ITYPENAME
#undef ITYPE


