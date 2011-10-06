/*
 * iir_order2.h --
 *
 *	Management of second-order IIR filters.
 *
 * Copyright (c) 2011 by Kevin B. Kenny.
 *
 * See the file "license.terms" for information on usage and redistribution of
 * this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 *-----------------------------------------------------------------------------
 */

/* Data structure holding the coefficients of a second-order IIR filter. */

typedef struct RecursiveOrder2Coefficients {
    double b0, b1, b2;
    double a1, a2;
} RecursiveOrder2Coefficients;

/* Functions for operating on second-order IIR filters */

extern void RecursiveOrder2Init(RecursiveOrder2Coefficients*,
				double, double, double, double, double);
				/* Initialize a second-order IIR filter */
extern void RecursiveOrder2ApplyForward(const RecursiveOrder2Coefficients*,
					int, int, float*, int, float*, int);
				/* Apply a second-order IIR filter in the
				 * causal direction*/

extern void RecursiveOrder2ApplyReverse(const RecursiveOrder2Coefficients*,
					int, int, float*, int, float*, int);
				/* Apply a second-order IIR filter in the
				 * anticausal direction */
extern void 
    RecursiveOrder2AccumulateForward(const RecursiveOrder2Coefficients*,
				     int, int, float*, int, float*,
				     int);
				/* Add the result of applying a second-order
				 * IIR filter in the causal direction to
				 * an array */
extern void 
    RecursiveOrder2AccumulateReverse(const RecursiveOrder2Coefficients*,
				     int, int, float*, int, float*,
				     int);
				/* Add the result of applying a second-order
				 * IIR filter in the anticausal direction
				 * to an array. */
