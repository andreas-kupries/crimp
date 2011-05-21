/*
 * fir.c --
 *
 *	Finite Impulse Response (FIR) convolution for short filters.
 *
 * Copyright (c) 2011 by Kevin B. Kenny.
 *
 * See the file "license.terms" for information on usage and redistribution of
 * this file, and for a DISCLAIMER OF ALL WARRANTIES.
 * 
 *-----------------------------------------------------------------------------
 */

#include <stdio.h>

/*
 *-----------------------------------------------------------------------------
 *
 * FIRConvolve --
 *
 *	Finite Impulse Response (FIR) convolution for short filters.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Stores the convolution product in the 'output' array.
 *
 * This function is useful for applying filters where the number of
 * coefficients is small enough that taking the filter into the
 * Fourier domain is more expensive than simple convolution.  It is
 * useful for applying such things as a derivative filter (-0.5, 0,
 * 0.5), a Laplacian filter (0.5 -1.0 0.5), Gaussians and their
 * derivatives of small radius, and windowed-sinc with small window
 * width.
 * 
 *-----------------------------------------------------------------------------
 */

void
FIRConvolve(
    int n,			/* Number of elements in the kernel:
				 * must be odd. */
    float* kernel,		/* Kernel of the filter */
    int m,			/* Number of elements in the input and output
				 * arrays: must be >= (n+1)/2 */
    float* input,		/* Input array to be convolved */
    int inputStride,		/* Stride of the input array */
    float* output,		/* Output array, must not be the same as
				 * the input. */
    int outputStride		/* Stride of the output array */
) {

    int k = n / 2;		/* Midpoint of the kernel */
    float out;			/* Output element being constructed */
    int i, j;

    /* Accumulate the output function */

    for (i = 0; i < m; ++i) {
	out = 0.0f;
	for (j = -k; i + j < 0; ++j) {
	    out += input[inputStride*(-j - i)] * kernel[k + j];
	}
	for (; i + j < m && j <= k; ++j) {
	    out += input[inputStride*(i + j)] * kernel[k + j];
	}
	for (; j <= k; ++j) {
	    out += input[inputStride*(2*m - j - i - 2)] * kernel[k + j];
	}
	output[i * outputStride] = out;
    }
}

/*
 *-----------------------------------------------------------------------------
 *
 * FIRAccumulate --
 *
 *	Finite Impulse Response (FIR) convolution for short filters.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Adds the convolution product to the 'output' array.
 *
 * This function is useful for applying filters where the number of
 * coefficients is small enough that taking the filter into the
 * Fourier domain is more expensive than simple convolution.  It is
 * useful for applying such things as a derivative filter (-0.5, 0,
 * 0.5), a Laplacian filter (0.5 -1.0 0.5), Gaussians and their
 * derivatives of small radius, and windowed-sinc with small window
 * width.
 * 
 *-----------------------------------------------------------------------------
 */

void
FIRAccumulate(
    int n,			/* Number of elements in the kernel:
				 * must be odd. */
    float* kernel,		/* Kernel of the filter */
    int m,			/* Number of elements in the input and output
				 * arrays: must be >= (n+1)/2 */
    float* input,		/* Input array to be convolved */
    int inputStride,		/* Stride of the input array */
    float* output,		/* Output array, must not be the same as
				 * the input. */
    int outputStride		/* Stride of the output array */
) {

    int k = n / 2;		/* Midpoint of the kernel */
    float out;			/* Output element being constructed */
    int i, j;

    /* Accumulate the output function */

    for (i = 0; i < m; ++i) {
	out = 0.0f;
	for (j = -k; i + j < 0; ++j) {
	    out += input[inputStride*(-j - i)] * kernel[k + j];
	}
	for (; i + j < m && j <= k; ++j) {
	    out += input[inputStride*(i + j)] * kernel[k + j];
	}
	for (; j <= k; ++j) {
	    out += input[inputStride*(2*m - j - i - 2)] * kernel[k + j];
	}
	output[i * outputStride] += out;
    }
}
