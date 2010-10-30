/* ezfftb.f -- translated by f2c (version 20050501).
   You must link the resulting object file with libf2c:
	on Microsoft Windows system, link with libf2c.lib;
	on Linux or Unix systems, link with .../path/to/libf2c.a -lm
	or, if you install libf2c.a in a standard place, with -lf2c -lm
	-- in that order, at the end of the command line, as in
		cc *.o -lf2c -lm
	Source for libf2c is in /netlib/f2c/libf2c.zip, e.g.,

		http://www.netlib.org/f2c/libf2c.zip
*/

#include "f2c.h"

/* Subroutine */ int ezfftb_(integer *n, real *r__, real *azero, real *a, 
	real *b, real *wsave)
{
    /* System generated locals */
    integer i__1;

    /* Local variables */
    integer i__, ns2;
    extern /* Subroutine */ int rfftb_(integer *, real *, real *);

    /* Parameter adjustments */
    --wsave;
    --b;
    --a;
    --r__;

    /* Function Body */
    if ((i__1 = *n - 2) < 0) {
	goto L101;
    } else if (i__1 == 0) {
	goto L102;
    } else {
	goto L103;
    }
L101:
    r__[1] = *azero;
    return 0;
L102:
    r__[1] = *azero + a[1];
    r__[2] = *azero - a[1];
    return 0;
L103:
    ns2 = (*n - 1) / 2;
    i__1 = ns2;
    for (i__ = 1; i__ <= i__1; ++i__) {
	r__[i__ * 2] = a[i__] * .5f;
	r__[(i__ << 1) + 1] = b[i__] * -.5f;
/* L104: */
    }
    r__[1] = *azero;
    if (*n % 2 == 0) {
	r__[*n] = a[ns2 + 1];
    }
    rfftb_(n, &r__[1], &wsave[*n + 1]);
    return 0;
} /* ezfftb_ */

