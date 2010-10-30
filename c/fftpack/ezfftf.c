/* ezfftf.f -- translated by f2c (version 20050501).
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

/* Subroutine */ int ezfftf_(integer *n, real *r__, real *azero, real *a, 
	real *b, real *wsave)
{
    /* System generated locals */
    integer i__1;

    /* Local variables */
    integer i__;
    real cf;
    integer ns2;
    real cfm;
    integer ns2m;
    extern /* Subroutine */ int rfftf_(integer *, real *, real *);


/*                       VERSION 3  JUNE 1979 */

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
    *azero = r__[1];
    return 0;
L102:
    *azero = (r__[1] + r__[2]) * .5f;
    a[1] = (r__[1] - r__[2]) * .5f;
    return 0;
L103:
    i__1 = *n;
    for (i__ = 1; i__ <= i__1; ++i__) {
	wsave[i__] = r__[i__];
/* L104: */
    }
    rfftf_(n, &wsave[1], &wsave[*n + 1]);
    cf = 2.f / (real) (*n);
    cfm = -cf;
    *azero = cf * .5f * wsave[1];
    ns2 = (*n + 1) / 2;
    ns2m = ns2 - 1;
    i__1 = ns2m;
    for (i__ = 1; i__ <= i__1; ++i__) {
	a[i__] = cf * wsave[i__ * 2];
	b[i__] = cfm * wsave[(i__ << 1) + 1];
/* L105: */
    }
    if (*n % 2 == 1) {
	return 0;
    }
    a[ns2] = cf * .5f * wsave[*n];
    b[ns2] = 0.f;
    return 0;
} /* ezfftf_ */

