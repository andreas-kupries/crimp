/*
 * fft.h --
 *
 *	Definitions of functions for various forms of FFT.
 *	Header to supplement the c/fftp which comes without.
 *
 * Copyright (c) 2016 Andreas Kupris
 *
 * See the file "license.terms" for information on usage and redistribution of
 * this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 *-----------------------------------------------------------------------------
 */

extern int cffti_ (long *n, float *wsave);
extern int cfftf_ (long *n, float *c__, float *wsave);
extern int cfftb_ (long *n, float *c__, float *wsave);
