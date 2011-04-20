/*
 * z_recip.c --
 *
 *	Reciprocal of a double-precision complex number.
 *
 * Copyright (c) 2011 by Kevin B. Kenny.
 *
 * See the file "license.terms" for information on usage and redistribution of
 * this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 *-----------------------------------------------------------------------------
 */

#include <f2c.h>

/*
 *-----------------------------------------------------------------------------
 *
 * z_recip --
 *
 *	Reciprocal of a double precision complex number.
 *
 * Parameters:
 *	b - (OUTPUT) Pointer to the reciprocal
 *	a - Pointer to the original number.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Stores the reciprocal using the given pointer.
 *	Stores (NaN, NaN) if zero is given.
 *
 *-----------------------------------------------------------------------------
 */

void
z_recip(
    doublecomplex *b,
    doublecomplex *a
) {
    double d = a->r * a->r + a->i * a->i;
    b->r = a->r / d;
    b->i = -a->i / d;
}
