/*
 * fir.h --
 *
 *	Definitions of procedures for Finite Input Response (FIR)
 *	convolutions
 *
 * Copyright (c) 2011 by Kevin B. Kenny.
 *
 * See the file "license.terms" for information on usage and redistribution of
 * this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 *-----------------------------------------------------------------------------
 */

extern void FIRConvolve(int, float*, int, float*, int, float*, int);
extern void FIRAccumulate(int, float*, int, float*, int, float*, int);
