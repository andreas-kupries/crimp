/*
 *-----------------------------------------------------------------------------
 *
 * iir_order2.c --
 *
 *	Apply (or accumulate) a second-order IIR filter.
 *
 * This file contains many procedures that, given the second order
 * filter coefficients G(z)= (b0 + b1*z + b2z**2) / (1 + a1z + a2*z**2)
 * apply the filter. There are a number of special cases for various
 * among the coefficients being zero.
 *
 * The cases include:
 *	Case 1: b1 = b2 = a2 = 0
 *	Case 2: b2 = a2 = 0
 *	Case 3: b2 = 0
 *	Case 4: b0 = 0
 *	Case 5 (General Case): None of the above
 *
 * The methods include:
 *	ApplyForward - Apply the filter in the forward (causal) direction
 *	ApplyReverse - Apply the filter in the reverse (anticausal) direction
 *	AccumulateForward - Apply the filter forward and sum to the output
 *	AccumulateReverse - Apply the filter in reverse and sum to the output
 *
 * Copyright (c) 2011 by Kevin B. Kenny.
 *
 * See the file "license.terms" for information on usage and redistribution of
 * this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 *-----------------------------------------------------------------------------
 */

#include <math.h>
#include <stdlib.h>

#include "iir_order2.h"

/*
 *-----------------------------------------------------------------------------
 *
 * RecursiveOrder2Init --
 *
 *	Initializes a second-order IIR filter.
 *
 * Parameters:
 *	b0, b1, b2 - Constant, z, z**2 coefficients in the numerator
 *	a1, a2 - z, z**2 coefficients in the denominator
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Stores the parameters in the filter's data structure.
 *
 *-----------------------------------------------------------------------------
 */

void
RecursiveOrder2Init(
    RecursiveOrder2Coefficients* filter,
    double b0,
    double b1,
    double b2,
    double a1,
    double a2
) {
    filter->b0 = b0; filter->b1 = b1; filter->b2 = b2;
    filter->a1 = a1; filter->a2 = a2;
}

/*
 *-----------------------------------------------------------------------------
 *
 * Inline procedures to specialize the loops
 *
 *-----------------------------------------------------------------------------
 */

inline static void
RO2ApplyForwardCase1(
    double b0,		     	/* constant term in numerator */
    double a1,			/* z term in denominator */
    int n,			/* Size of the arrays */
    int prime,			/* Size of the "pump priming" loop */
    float* x,			/* Input array */
    int xStride,		/* Stride of the input array */
    float* y,			/* Output array */
    int yStride			/* Stride of the output array */
) {
    int i;
    double yim1 = 0.0f;
    for (i = prime - 1; i >= 0; --i) {
	double xi = x[i * xStride];
	double yi = b0 * xi - a1 * yim1;
	yim1 = yi;
    }
    for (i = 0; i < n; ++i) {
	double xi = x[i * xStride];
	double yi = b0 * xi - a1 * yim1;
	y[i * yStride] = yi;
	yim1 = yi;
    }
}
inline static void
RO2ApplyForwardCase2(			  
    double b0,		     	/* constant term in numerator */
    double b1,			/* z term in numerator */
    double a1,			/* z term in denominator */
    int n,			/* Size of the arrays */
    int prime,			/* Size of the "pump priming" loop */
    float* x,			/* Input array */
    int xStride,		/* Stride of the input array */
    float* y,			/* Output array */
    int yStride			/* Stride of the output array */
) {
    int i;
    double xim1 = 0.0f;
    double yim1 = 0.0f;
    for (i = prime - 1; i >= 0; --i) {
	double xi = x[i * xStride];
	double yi = b0 * xi + b1 * xim1 - a1 * yim1;
	xim1 = xi;
	yim1 = yi;
    }
    for (i = 0; i < n; ++i) {
	double xi = x[i * xStride];
	double yi = b0 * xi + b1 * xim1 - a1 * yim1;
	y[i * yStride] = yi;
	xim1 = xi;
	yim1 = yi;
    }
}
inline static void
RO2ApplyForwardCase3(			  
    double b0,		     	/* constant term in numerator */
    double b1,			/* z term in numerator */
    double a1,			/* z term in denominator */
    double a2,			/* z**2 term in denominator */
    int n,			/* Size of the arrays */
    int prime,			/* Size of the "pump priming" loop */
    float* x,			/* Input array */
    int xStride,		/* Stride of the input array */
    float* y,			/* Output array */
    int yStride			/* Stride of the output array */
) {
    int i;
    double xim1 = 0.0f;
    double yim1 = 0.0f, yim2 = 0.0f;
    for (i = prime - 1; i >= 0; --i) {
	double xi = x[i * xStride];
	double yi = b0 * xi + b1 * xim1 - a1 * yim1 - a2 * yim2;
	xim1 = xi;
	yim2 = yim1; yim1 = yi; 
    }
    for (i = 0; i < n; ++i) {
	double xi = x[i * xStride];
	double yi = b0 * xi + b1 * xim1 - a1 * yim1 - a2 * yim2;
	y[i * yStride] = yi;
	xim1 = xi;
	yim2 = yim1; yim1 = yi; 
    }
}
inline static void
RO2ApplyForwardCase4(			  
    double b1,			/* z term in numerator */
    double b2,			/* z**2 term in numerator */
    double a1,			/* z term in denominator */
    double a2,			/* z**2 term in denominator */
    int n,			/* Size of the arrays */
    int prime,			/* Size of the "pump priming" loop */
    float* x,			/* Input array */
    int xStride,		/* Stride of the input array */
    float* y,			/* Output array */
    int yStride			/* Stride of the output array */
) {
    int i;
    double xim1 = 0.0f, xim2 = 0.0f;
    double yim1 = 0.0f, yim2 = 0.0f;
    for (i = prime - 1; i >= 0; --i) {
	double xi = x[i * xStride];
	double yi = b1 * xim1 + b2 * xim2 - a1 * yim1 - a2 * yim2;
	xim2 = xim1; xim1 = xi;
	yim2 = yim1; yim1 = yi; 
    }
    for (i = 0; i < n; ++i) {
	double xi = x[i * xStride];
	double yi = b1 * xim1 + b2 * xim2 - a1 * yim1 - a2 * yim2;
	y[i * yStride] = yi;
	xim2 = xim1; xim1 = xi;
	yim2 = yim1; yim1 = yi; 
    }
}

inline static void
RO2ApplyForwardGeneralCase(
    double b0,			/* constant term in numerator */
    double b1,			/* z term in numerator */
    double b2,			/* z**2 term in numerator */
    double a1,			/* z term in denominator */
    double a2,			/* z**2 term in denominator */
    int n,			/* Size of the arrays */
    int prime,			/* Size of the "pump priming" loop */
    float* x,			/* Input array */
    int xStride,		/* Stride of the input array */
    float* y,			/* Output array */
    int yStride			/* Stride of the output array */
) {
    int i;
    double xim1 = 0.0f, xim2 = 0.0f;
    double yim1 = 0.0f, yim2 = 0.0f;
    for (i = prime - 1; i >= 0; --i) {
	double xi = x[i * xStride];
	double yi = b0 * xi + b1 * xim1 + b2 * xim2 - a1 * yim1 - a2 * yim2;
	xim2 = xim1; xim1 = xi;
	yim2 = yim1; yim1 = yi; 
    }
    for (i = 0; i < n; ++i) {
	double xi = x[i * xStride];
	double yi = b0 * xi + b1 * xim1 + b2 * xim2 - a1 * yim1 - a2 * yim2;
	y[i * yStride] = yi;
	xim2 = xim1; xim1 = xi;
	yim2 = yim1; yim1 = yi; 
    }
}

inline static void
RO2ApplyReverseCase1(
    double b0,		     	/* constant term in numerator */
    double a1,			/* z term in denominator */
    int n,			/* Size of the arrays */
    int prime,			/* Size of the "pump priming" loop */
    float* x,			/* Input array */
    int xStride,		/* Stride of the input array */
    float* y,			/* Output array */
    int yStride			/* Stride of the output array */
) {
    int i;
    double yip1 = 0.0f;
    for (i = n - prime; i < n; ++i) {
	double xi = x[i * xStride];
	double yi = b0 * xi - a1 * yip1;
	yip1 = yi;
    }
    for (i = n-1; i >= 0; --i) {
	double xi = x[i * xStride];
	double yi = b0 * xi - a1 * yip1;
	y[i * yStride] = yi;
	yip1 = yi;
    }
}
inline static void
RO2ApplyReverseCase2(			  
    double b0,		     	/* constant term in numerator */
    double b1,			/* z term in numerator */
    double a1,			/* z term in denominator */
    int n,			/* Size of the arrays */
    int prime,			/* Size of the "pump priming" loop */
    float* x,			/* Input array */
    int xStride,		/* Stride of the input array */
    float* y,			/* Output array */
    int yStride			/* Stride of the output array */
) {
    int i;
    double xip1 = 0.0f;
    double yip1 = 0.0f;
    for (i = n - prime; i < n; ++i) {
	double xi = x[i * xStride];
	double yi = b0 * xi + b1 * xip1 - a1 * yip1;
	xip1 = xi;
	yip1 = yi;
    }
    for (i = n-1; i >= 0; --i) {
	double xi = x[i * xStride];
	double yi = b0 * xi + b1 * xip1 - a1 * yip1;
	y[i * yStride] = yi;
	xip1 = xi;
	yip1 = yi;
    }
}
inline static void
RO2ApplyReverseCase3(			  
    double b0,		     	/* constant term in numerator */
    double b1,			/* z term in numerator */
    double a1,			/* z term in denominator */
    double a2,			/* z**2 term in denominator */
    int n,			/* Size of the arrays */
    int prime,			/* Size of the "pump priming" loop */
    float* x,			/* Input array */
    int xStride,		/* Stride of the input array */
    float* y,			/* Output array */
    int yStride			/* Stride of the output array */
) {
    int i;
    double xip1 = 0.0f;
    double yip1 = 0.0f, yip2 = 0.0f;
    for (i = n-prime; i < n; ++i) {
	double xi = x[i * xStride];
	double yi = b0 * xi + b1 * xip1 - a1 * yip1 - a2 * yip2;
	xip1 = xi;
	yip2 = yip1; yip1 = yi; 
    }
    for (i = n-1; i >= 0; --i) {
	double xi = x[i * xStride];
	double yi = b0 * xi + b1 * xip1 - a1 * yip1 - a2 * yip2;
	y[i * yStride] = yi;
	xip1 = xi;
	yip2 = yip1; yip1 = yi; 
    }
}
inline static void
RO2ApplyReverseCase4(			  
    double b1,			/* z term in numerator */
    double b2,			/* z**2 term in numerator */
    double a1,			/* z term in denominator */
    double a2,			/* z**2 term in denominator */
    int n,			/* Size of the arrays */
    int prime,			/* Size of the "pump priming" loop */
    float* x,			/* Input array */
    int xStride,		/* Stride of the input array */
    float* y,			/* Output array */
    int yStride			/* Stride of the output array */
) {
    int i;
    double xip1 = 0.0f, xip2 = 0.0f;
    double yip1 = 0.0f, yip2 = 0.0f;
    for (i = n-prime; i < n; ++i) {
	double xi = x[i * xStride];
	double yi = b1 * xip1 + b2 * xip2 - a1 * yip1 - a2 * yip2;
	xip2 = xip1; xip1 = xi;
	yip2 = yip1; yip1 = yi; 
    }
    for (i = n-1; i >= 0; --i) {
	double xi = x[i * xStride];
	double yi = b1 * xip1 + b2 * xip2 - a1 * yip1 - a2 * yip2;
	y[i * yStride] = yi;
	xip2 = xip1; xip1 = xi;
	yip2 = yip1; yip1 = yi; 
    }
}

inline static void
RO2ApplyReverseGeneralCase(
    double b0,			/* constant term in numerator */
    double b1,			/* z term in numerator */
    double b2,			/* z**2 term in numerator */
    double a1,			/* z term in denominator */
    double a2,			/* z**2 term in denominator */
    int n,			/* Size of the arrays */
    int prime,			/* Size of the "pump priming" loop */
    float* x,			/* Input array */
    int xStride,		/* Stride of the input array */
    float* y,			/* Output array */
    int yStride			/* Stride of the output array */
) {
    int i;
    double xip1 = 0.0f, xip2 = 0.0f;
    double yip1 = 0.0f, yip2 = 0.0f;
    for (i = n-prime; i < n; ++i) {
	double xi = x[i * xStride];
	double yi = b0 * xi + b1 * xip1 + b2 * xip2 - a1 * yip1 - a2 * yip2;
	xip2 = xip1; xip1 = xi;
	yip2 = yip1; yip1 = yi; 
    }
    for (i = n-1; i >= 0; --i) {
	double xi = x[i * xStride];
	double yi = b0 * xi + b1 * xip1 + b2 * xip2 - a1 * yip1 - a2 * yip2;
	y[i * yStride] = yi;
	xip2 = xip1; xip1 = xi;
	yip2 = yip1; yip1 = yi; 
    }
}

inline static void
RO2AccumulateForwardCase1(
    double b0,		     	/* constant term in numerator */
    double a1,			/* z term in denominator */
    int n,			/* Size of the arrays */
    int prime,			/* Size of the "pump priming" loop */
    float* x,			/* Input array */
    int xStride,		/* Stride of the input array */
    float* y,			/* Output array */
    int yStride			/* Stride of the output array */
) {
    int i;
    double yim1 = 0.0f;
    for (i = prime-1; i >= 0; --i) {
	double xi = x[i * xStride];
	double yi = b0 * xi - a1 * yim1;
	yim1 = yi;
    }
    for (i = 0; i < n; ++i) {
	double xi = x[i * xStride];
	double yi = b0 * xi - a1 * yim1;
	y[i * yStride] += yi;
	yim1 = yi;
    }
}
inline static void
RO2AccumulateForwardCase2(			  
    double b0,		     	/* constant term in numerator */
    double b1,			/* z term in numerator */
    double a1,			/* z term in denominator */
    int n,			/* Size of the arrays */
    int prime,			/* Size of the "pump priming" loop */
    float* x,			/* Input array */
    int xStride,		/* Stride of the input array */
    float* y,			/* Output array */
    int yStride			/* Stride of the output array */
) {
    int i;
    double xim1 = 0.0f;
    double yim1 = 0.0f;
    for (i = prime-1; i >= 0; --i) {
	double xi = x[i * xStride];
	double yi = b0 * xi + b1 * xim1 - a1 * yim1;
	xim1 = xi;
	yim1 = yi;
    }
    for (i = 0; i < n; ++i) {
	double xi = x[i * xStride];
	double yi = b0 * xi + b1 * xim1 - a1 * yim1;
	y[i * yStride] += yi;
	xim1 = xi;
	yim1 = yi;
    }
}
inline static void
RO2AccumulateForwardCase3(			  
    double b0,		     	/* constant term in numerator */
    double b1,			/* z term in numerator */
    double a1,			/* z term in denominator */
    double a2,			/* z**2 term in denominator */
    int n,			/* Size of the arrays */
    int prime,			/* Size of the "pump priming" loop */
    float* x,			/* Input array */
    int xStride,		/* Stride of the input array */
    float* y,			/* Output array */
    int yStride			/* Stride of the output array */
) {
    int i;
    double xim1 = 0.0f;
    double yim1 = 0.0f, yim2 = 0.0f;
    for (i = prime-1; i >= 0; --i) {
	double xi = x[i * xStride];
	double yi = b0 * xi + b1 * xim1 - a1 * yim1 - a2 * yim2;
	xim1 = xi;
	yim2 = yim1; yim1 = yi; 
    }
    for (i = 0; i < n; ++i) {
	double xi = x[i * xStride];
	double yi = b0 * xi + b1 * xim1 - a1 * yim1 - a2 * yim2;
	y[i * yStride] += yi;
	xim1 = xi;
	yim2 = yim1; yim1 = yi; 
    }
}
inline static void
RO2AccumulateForwardCase4(			  
    double b1,			/* z term in numerator */
    double b2,			/* z**2 term in numerator */
    double a1,			/* z term in denominator */
    double a2,			/* z**2 term in denominator */
    int n,			/* Size of the arrays */
    int prime,			/* Size of the "pump priming" loop */
    float* x,			/* Input array */
    int xStride,		/* Stride of the input array */
    float* y,			/* Output array */
    int yStride			/* Stride of the output array */
) {
    int i;
    double xim1 = 0.0f, xim2 = 0.0f;
    double yim1 = 0.0f, yim2 = 0.0f;
    for (i = prime-1; i >= 0; --i) {
	double xi = x[i * xStride];
	double yi = b1 * xim1 + b2 * xim2 - a1 * yim1 - a2 * yim2;
	xim2 = xim1; xim1 = xi;
	yim2 = yim1; yim1 = yi; 
    }
    for (i = 0; i < n; ++i) {
	double xi = x[i * xStride];
	double yi = b1 * xim1 + b2 * xim2 - a1 * yim1 - a2 * yim2;
	y[i * yStride] += yi;
	xim2 = xim1; xim1 = xi;
	yim2 = yim1; yim1 = yi; 
    }
}

inline static void
RO2AccumulateForwardGeneralCase(
    double b0,			/* constant term in numerator */
    double b1,			/* z term in numerator */
    double b2,			/* z**2 term in numerator */
    double a1,			/* z term in denominator */
    double a2,			/* z**2 term in denominator */
    int n,			/* Size of the arrays */
    int prime,			/* Size of the "pump priming" loop */
    float* x,			/* Input array */
    int xStride,		/* Stride of the input array */
    float* y,			/* Output array */
    int yStride			/* Stride of the output array */
) {
    int i;
    double xim1 = 0.0f, xim2 = 0.0f;
    double yim1 = 0.0f, yim2 = 0.0f;
    for (i = prime-1; i >= 0; --i) {
	double xi = x[i * xStride];
	double yi = b0 * xi + b1 * xim1 + b2 * xim2 - a1 * yim1 - a2 * yim2;
	xim2 = xim1; xim1 = xi;
	yim2 = yim1; yim1 = yi; 
    }
    for (i = 0; i < n; ++i) {
	double xi = x[i * xStride];
	double yi = b0 * xi + b1 * xim1 + b2 * xim2 - a1 * yim1 - a2 * yim2;
	y[i * yStride] += yi;
	xim2 = xim1; xim1 = xi;
	yim2 = yim1; yim1 = yi; 
    }
}

inline static void
RO2AccumulateReverseCase1(
    double b0,		     	/* constant term in numerator */
    double a1,			/* z term in denominator */
    int n,			/* Size of the arrays */
    int prime,			/* Size of the "pump priming" loop */
    float* x,			/* Input array */
    int xStride,		/* Stride of the input array */
    float* y,			/* Output array */
    int yStride			/* Stride of the output array */
) {
    int i;
    double yip1 = 0.0f;
    for (i = n-prime; i < n; ++i) {
	double xi = x[i * xStride];
	double yi = b0 * xi - a1 * yip1;
	y[i * yStride] += yi;
	yip1 = yi;
    }
    for (i = n-1; i >= 0; --i) {
	double xi = x[i * xStride];
	double yi = b0 * xi - a1 * yip1;
	y[i * yStride] += yi;
	yip1 = yi;
    }
}
inline static void
RO2AccumulateReverseCase2(			  
    double b0,		     	/* constant term in numerator */
    double b1,			/* z term in numerator */
    double a1,			/* z term in denominator */
    int n,			/* Size of the arrays */
    int prime,			/* Size of the "pump priming" loop */
    float* x,			/* Input array */
    int xStride,		/* Stride of the input array */
    float* y,			/* Output array */
    int yStride			/* Stride of the output array */
) {
    int i;
    double xip1 = 0.0f;
    double yip1 = 0.0f;
    for (i = n-prime; i < n; ++i) {
	double xi = x[i * xStride];
	double yi = b0 * xi + b1 * xip1 - a1 * yip1;
	xip1 = xi;
	yip1 = yi;
    }
    for (i = n-1; i >= 0; --i) {
	double xi = x[i * xStride];
	double yi = b0 * xi + b1 * xip1 - a1 * yip1;
	y[i * yStride] += yi;
	xip1 = xi;
	yip1 = yi;
    }
}
inline static void
RO2AccumulateReverseCase3(			  
    double b0,		     	/* constant term in numerator */
    double b1,			/* z term in numerator */
    double a1,			/* z term in denominator */
    double a2,			/* z**2 term in denominator */
    int n,			/* Size of the arrays */
    int prime,			/* Size of the "pump priming" loop */
    float* x,			/* Input array */
    int xStride,		/* Stride of the input array */
    float* y,			/* Output array */
    int yStride			/* Stride of the output array */
) {
    int i;
    double xip1 = 0.0f;
    double yip1 = 0.0f, yip2 = 0.0f;
    for (i = n-prime; i < n; ++i) {
	double xi = x[i * xStride];
	double yi = b0 * xi + b1 * xip1 - a1 * yip1 - a2 * yip2;
	xip1 = xi;
	yip2 = yip1; yip1 = yi; 
    }
    for (i = n-1; i >= 0; --i) {
	double xi = x[i * xStride];
	double yi = b0 * xi + b1 * xip1 - a1 * yip1 - a2 * yip2;
	y[i * yStride] += yi;
	xip1 = xi;
	yip2 = yip1; yip1 = yi; 
    }
}
inline static void
RO2AccumulateReverseCase4(			  
    double b1,			/* z term in numerator */
    double b2,			/* z**2 term in numerator */
    double a1,			/* z term in denominator */
    double a2,			/* z**2 term in denominator */
    int n,			/* Size of the arrays */
    int prime,			/* Size of the "pump priming" loop */
    float* x,			/* Input array */
    int xStride,		/* Stride of the input array */
    float* y,			/* Output array */
    int yStride			/* Stride of the output array */
) {
    int i;
    double xip1 = 0.0f, xip2 = 0.0f;
    double yip1 = 0.0f, yip2 = 0.0f;
    for (i = n-prime; i < n; ++i) {
	double xi = x[i * xStride];
	double yi = b1 * xip1 + b2 * xip2 - a1 * yip1 - a2 * yip2;
	xip2 = xip1; xip1 = xi;
	yip2 = yip1; yip1 = yi; 
    }
    for (i = n-1; i >= 0; --i) {
	double xi = x[i * xStride];
	double yi = b1 * xip1 + b2 * xip2 - a1 * yip1 - a2 * yip2;
	y[i * yStride] += yi;
	xip2 = xip1; xip1 = xi;
	yip2 = yip1; yip1 = yi; 
    }
}

inline static void
RO2AccumulateReverseGeneralCase(
    double b0,			/* constant term in numerator */
    double b1,			/* z term in numerator */
    double b2,			/* z**2 term in numerator */
    double a1,			/* z term in denominator */
    double a2,			/* z**2 term in denominator */
    int n,			/* Size of the arrays */
    int prime,			/* Size of the "pump priming" loop */
    float* x,			/* Input array */
    int xStride,		/* Stride of the input array */
    float* y,			/* Output array */
    int yStride			/* Stride of the output array */
) {
    int i;
    double xip1 = 0.0f, xip2 = 0.0f;
    double yip1 = 0.0f, yip2 = 0.0f;
    for (i = n-prime; i < n; ++i) {
	double xi = x[i * xStride];
	double yi = b0 * xi + b1 * xip1 + b2 * xip2 - a1 * yip1 - a2 * yip2;
	xip2 = xip1; xip1 = xi;
	yip2 = yip1; yip1 = yi; 
    }
    for (i = n-1; i >= 0; --i) {
	double xi = x[i * xStride];
	double yi = b0 * xi + b1 * xip1 + b2 * xip2 - a1 * yip1 - a2 * yip2;
	y[i * yStride] += yi;
	xip2 = xip1; xip1 = xi;
	yip2 = yip1; yip1 = yi; 
    }
}

/*
 *-----------------------------------------------------------------------------
 *
 * RecursiveOrder2ApplyForward --
 *
 *	Apply a second-order IIR filter in the forward direction.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Stores the filtered function in the 'y' array.
 *
 * It is permissible to filter 'in place', that is, the 'y' array may
 * be the same as the 'x'.
 *
 *-----------------------------------------------------------------------------
 */

void
RecursiveOrder2ApplyForward(
    const RecursiveOrder2Coefficients* filterPtr,
				/* Filter to apply */
    int n,			/* Size of the arrays */
    int prime,			/* Size of the "pump priming" loop */
    float* x,			/* Input array */
    int xStride,		/* Stride of the input array */
    float* y,			/* Output array */
    int yStride			/* Stride of the output array */
) {
    double b0 = filterPtr->b0;
    double b1 = filterPtr->b1;
    double b2 = filterPtr->b2;
    double a1 = filterPtr->a1;
    double a2 = filterPtr->a2;
    
    if (b2 == 0.0f) {
	if (a2 == 0.0f) {
	    if (b1 == 0.0f) {
		RO2ApplyForwardCase1(b0, a1, n, prime, x, xStride, y, yStride);
	    } else {
		RO2ApplyForwardCase2(b0, b1, a2,
				     n, prime, x, xStride, y, yStride);
	    }
	} else {
	    RO2ApplyForwardCase3(b0, b1, a1, a2,
				 n, prime, x, xStride, y, yStride);
	}
    } else if (b0 == 0.0f) {
	RO2ApplyForwardCase4(b1, b2, a1, a2, n, prime, x, xStride, y, yStride);
    } else {
	RO2ApplyForwardGeneralCase(b0, b1, b2, a1, a2,
				   n, prime, x, xStride, y, yStride);
    }
}

/*
 *-----------------------------------------------------------------------------
 *
 * RecursiveOrder2ApplyReverse --
 *
 *	Apply a second-order IIR filter in the reverse direction.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Stores the filtered function in the 'y' array.
 *
 * It is permissible to filter 'in place', that is, the 'y' array may
 * be the same as the 'x'.
 *
 *-----------------------------------------------------------------------------
 */

void
RecursiveOrder2ApplyReverse(
    const RecursiveOrder2Coefficients* filterPtr,
				/* Filter to apply */
    int n,			/* Size of the arrays */
    int prime,			/* Size of the "pump priming" loop */
    float* x,			/* Input array */
    int xStride,		/* Stride of the input array */
    float* y,			/* Output array */
    int yStride			/* Stride of the output array */
) {
    double b0 = filterPtr->b0;
    double b1 = filterPtr->b1;
    double b2 = filterPtr->b2;
    double a1 = filterPtr->a1;
    double a2 = filterPtr->a2;
    
    if (b2 == 0.0f) {
	if (a2 == 0.0f) {
	    if (b1 == 0.0f) {
		RO2ApplyReverseCase1(b0, a1, n, prime, x, xStride, y, yStride);
	    } else {
		RO2ApplyReverseCase2(b0, b1, a2,
				     n, prime, x, xStride, y, yStride);
	    }
	} else {
	    RO2ApplyReverseCase3(b0, b1, a1, a2,
				 n, prime, x, xStride, y, yStride);
	}
    } else if (b0 == 0.0f) {
	RO2ApplyReverseCase4(b1, b2, a1, a2, n, prime, x, xStride, y, yStride);
    } else {
	RO2ApplyReverseGeneralCase(b0, b1, b2, a1, a2,
				   n, prime, x, xStride, y, yStride);
    }
}

/*
 *-----------------------------------------------------------------------------
 *
 * RecursiveOrder2AccumulateForward --
 *
 *	Accumulate the result a second-order IIR filter in the forward
 *	direction.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Adds the filtered function in the 'y' array.
 *
 * It is permissible to filter 'in place', that is, the 'y' array may
 * be the same as the 'x'.
 *
 *-----------------------------------------------------------------------------
 */

void
RecursiveOrder2AccumulateForward(
    const RecursiveOrder2Coefficients* filterPtr,
				/* Filter to apply */
    int n,			/* Size of the arrays */
    int prime,			/* Size of the "pump priming" loop */
    float* x,			/* Input array */
    int xStride,		/* Stride of the input array */
    float* y,			/* Output array */
    int yStride			/* Stride of the output array */
) {
    double b0 = filterPtr->b0;
    double b1 = filterPtr->b1;
    double b2 = filterPtr->b2;
    double a1 = filterPtr->a1;
    double a2 = filterPtr->a2;
    
    if (b2 == 0.0f) {
	if (a2 == 0.0f) {
	    if (b1 == 0.0f) {
		RO2AccumulateForwardCase1(b0, a1,
					  n, prime, x, xStride, y, yStride);
	    } else {
		RO2AccumulateForwardCase2(b0, b1, a2,
					  n, prime, x, xStride, y, yStride);
	    }
	} else {
	    RO2AccumulateForwardCase3(b0, b1, a1, a2,
				      n, prime, x, xStride, y, yStride);
	}
    } else if (b0 == 0.0f) {
	RO2AccumulateForwardCase4(b1, b2, a1, a2,
				  n, prime, x, xStride, y, yStride);
    } else {
	RO2AccumulateForwardGeneralCase(b0, b1, b2, a1, a2,
					n, prime, x, xStride, y, yStride);
    }
}

/*
 *-----------------------------------------------------------------------------
 *
 * RecursiveOrder2AccumulateReverse --
 *
 *	Accumulate the result a second-order IIR filter in the reverse
 *	direction.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Adds the filtered function in the 'y' array.
 *
 * It is permissible to filter 'in place', that is, the 'y' array may
 * be the same as the 'x'.
 *
 *-----------------------------------------------------------------------------
 */

void
RecursiveOrder2AccumulateReverse(
    const RecursiveOrder2Coefficients* filterPtr,
				/* Filter to apply */
    int n,			/* Size of the arrays */
    int prime,			/* Size of the "pump priming" loop */
    float* x,			/* Input array */
    int xStride,		/* Stride of the input array */
    float* y,			/* Output array */
    int yStride			/* Stride of the output array */
) {
    double b0 = filterPtr->b0;
    double b1 = filterPtr->b1;
    double b2 = filterPtr->b2;
    double a1 = filterPtr->a1;
    double a2 = filterPtr->a2;
    
    if (b2 == 0.0f) {
	if (a2 == 0.0f) {
	    if (b1 == 0.0f) {
		RO2AccumulateReverseCase1(b0, a1, n, prime,
					  x, xStride, y, yStride);
	    } else {
		RO2AccumulateReverseCase2(b0, b1, a2, n, prime,
					  x, xStride, y, yStride);
	    }
	} else {
	    RO2AccumulateReverseCase3(b0, b1, a1, a2, n, prime,
				      x, xStride, y, yStride);
	}
    } else if (b0 == 0.0f) {
	RO2AccumulateReverseCase4(b1, b2, a1, a2, n, prime,
				  x, xStride, y, yStride);
    } else {
	RO2AccumulateReverseGeneralCase(b0, b1, b2, a1, a2, n, prime,
					x, xStride, y, yStride);
    }
}

