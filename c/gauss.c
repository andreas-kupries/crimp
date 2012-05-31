/*
 * gauss.c --
 *
 *	C implementation of convolution with a Gaussian filter and its
 *	derivatives.
 *
 * Copyright (c) 2011 by Kevin B. Kenny.
 *
 * See the file "license.terms" for information on usage and redistribution of
 * this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 *-----------------------------------------------------------------------------
 */

#include <tcl.h>

#include <math.h>
#include <memory.h>
#include <stdio.h>
#include <stdlib.h>
#include <f2c.h>	/* f2c.h must come after the system includes */

#include "util.h"
#include "gauss.h"
#include "fir.h"
#include "iir_order2.h"

/* f2c library procedures */

extern double z_abs(const doublecomplex*);
extern void z_div(const doublecomplex*, const doublecomplex*, doublecomplex*);

/* 
 * Complex reciprocal - this procedure should be in libf2c, but isn't
 */

extern void z_recip(const doublecomplex*, doublecomplex*);

/*
 * Data structures describing an FIR filter set
 */

typedef struct FIRFilterSet {
    int n;			/* Width of the support */
    float* coefs[3];		/* 3 n-element arrays of coefficients,
				 * one each for Gaussian, derivative,
				 * second derivative */
} FIRFilterSet;

/*
 * Data structures describing the Deriche filter set
 */

/* Precomputed coefficients (must be scaled) of a Deriche filter */

typedef struct DerichePrecomputed {
    double a0, a1, b0, b1, c0, c1, w0, w1;
} DerichePrecomputed;

/* Scaled coefficients of a Deriche filter. */

typedef struct DericheCoefficients {
    float n0, n1, n2, n3;
    float d1, d2, d3, d4;
} DericheCoefficients;

/* 
 * A Deriche filter set has separate coefficients for the Gaussian and
 * its first and second derivatives.
 */

typedef struct DericheFilterSet {
    DericheCoefficients coefs[3];
} DericheFilterSet;

/*
 * Data structures describing the Van Vliet filter set
 */

/* Which direction (forward or reverse) are we building a filter for */

typedef enum VanVlietDirection {
    VVD_FORWARD=0, VVD_REVERSE, VVD_MAX
} VanVlietDirection;

/* Which pass are we building a filter for */

typedef enum VanVlietPass {
    VVP_PASS1=0, VVP_PASS2, VVP_MAX
} VanVlietPass;

/* 
 * A Van Vliet filter also comprises three filters: one each for the
 * Gaussian and its first two derivatives.  Each of those has two filters
 * to be applied; each of those two filters breaks down into causal and
 * anticausal components.
 */

typedef struct VanVlietFilterSet {
    RecursiveOrder2Coefficients coefs[3][VVP_MAX][VVD_MAX];
} VanVlietFilterSet;

/* 
 * Data structure describing a Gaussian derivative filter, whether FIR,
 * Deriche or Van Vliet
 */

/*
 * What algorithm is used to implement the filter?
 */

typedef enum GaussianFilterType {
    GFT_FIR,
    GFT_DERICHE, 
    GFT_VANVLIET
} GaussianFilterType;

/*
 * A Gaussian filter set comprises either a set of FIR filters for
 * convolution, a Deriche filter set, or a Van Vliet filter set.
 */

struct GaussianFilterSet_ {
    GaussianFilterType type;	/* Type of the filter */
    double sigma;		/* Width of the filter */
    union {
	FIRFilterSet fir;
	DericheFilterSet deriche;
	VanVlietFilterSet vanvliet;
    } filters;			/* Filter coefficients */
};

/* Static routines defined within this file */

static void FIRInitFilterSet(FIRFilterSet*, double);
static void FIRApply(FIRFilterSet*, int, int, float*, int, float*, int);
static void FIRDestroyFilterSet(FIRFilterSet* filterPtr);
static void DericheInitFilterSet(DericheFilterSet*, double);
static void DericheApply(DericheFilterSet*, int, int, 
			 float*, int, float*, int, double);
static void DericheInitCoefficients(int, DericheCoefficients*,
				    const DerichePrecomputed*, double);
static void DericheScaleN(DericheFilterSet*, double);
static void VanVlietAdjustPoles(const doublecomplex[4], double,
				doublecomplex[4]);
static void VanVlietInitFilterSet(VanVlietFilterSet*, double);
static void VanVlietApply(VanVlietFilterSet*, int, int, 
			  float*, int, float*, int, double);
static double VanVlietComputeSigma(double, const doublecomplex[4]);
static double VanVlietComputeGain(const doublecomplex[4]);
static void VanVlietResidue(int, const doublecomplex*, 
			    const doublecomplex[4], double,
			    doublecomplex*);

/*
 *-----------------------------------------------------------------------------
 *
 * GaussianCreateFilter --
 *
 *	Create the data needed to convolve images with a Gaussian derivative.
 *
 * Results:
 *	Returns an opaque pointer to the data structure used for convolution.
 *
 * The pointer may be freed with GaussianDeleteFilter.
 *
 *-----------------------------------------------------------------------------
 */

GaussianFilterSet
GaussianCreateFilter(
    double sigma	 /* Standard deviation - radius of Gaussian */
) {

    /* 
     * Allocate space and store standard deviation 
     */

    GaussianFilterSet filterPtr = (GaussianFilterSet)
	ckalloc(sizeof (*filterPtr));
    filterPtr->sigma = sigma;

    /* TODO: Deriche and Van Vliet go wrong for sigma < 1. Implement
     * FIR convolution */

    if (sigma <= 3.0) {

	/* 
	 * For very small radii, just use an FIR filter applied in the
	 * pixel domain.
	 */
	filterPtr->type = GFT_FIR;
	FIRInitFilterSet(&filterPtr->filters.fir, sigma);
    } else if (sigma <= 30.0) {

	/* 
	 * Deriche is a better model for intermediate values of sigma 
	 */

	filterPtr->type = GFT_DERICHE;
	DericheInitFilterSet(&filterPtr->filters.deriche, sigma);
    } else {

	/* 
	 * Van Vliet is most stable for large sigma values 
	 */

	filterPtr->type = GFT_VANVLIET;
	VanVlietInitFilterSet(&filterPtr->filters.vanvliet, sigma);
    }
    return filterPtr;
}

/*
 *-----------------------------------------------------------------------------
 *
 * GaussianApplyFilter --
 *
 *	Convolve a function with a Gaussian or one of its derivatives.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Fills in the 'y' array with the convolution product.
 *
 *-----------------------------------------------------------------------------
 */

void
GaussianApplyFilter(
    GaussianFilterSet filterPtr, 
				/* Filter to apply, from
				 * GaussianCreateFilter  */
    int whichDeriv,		/* Which derivative (0, 1, 2)  */
    int n,			/* Number of data points to convolve */
    float* x,			/* Input function - n-element array */
    int xStride,		/* Stride of the input array (1==contiguous) */
    float* y,			/* Output function - n-element array */
    int yStride			/* Stride of the output array (1==contiguous */
) {

    /* 
     * Call the appropriate code to apply the filter 
     */

    switch (filterPtr->type) {
    case GFT_FIR:
	FIRApply(&filterPtr->filters.fir,
		 whichDeriv, n, x, xStride, y, yStride);
	break;
    case GFT_DERICHE:
	DericheApply(&filterPtr->filters.deriche,
		     whichDeriv, n, x, xStride, y, yStride, filterPtr->sigma);
	break;
    case GFT_VANVLIET:
	VanVlietApply(&filterPtr->filters.vanvliet,
		      whichDeriv, n, x, xStride, y, yStride, filterPtr->sigma);
	break;
    }
}

/*
 *-----------------------------------------------------------------------------
 *
 * GaussianDeleteFilter --
 *
 *	Frees a Gaussian filter when the program is done with it.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Resources are returned to the system.
 *
 *-----------------------------------------------------------------------------
 */

void 
GaussianDeleteFilter(
    GaussianFilterSet filterPtr	/* Filter to free */
) {
    switch(filterPtr->type) {
    case GFT_FIR:
	FIRDestroyFilterSet(&filterPtr->filters.fir);
	break;
    default: 
	break;
    }
    ckfree((char*)filterPtr);
}

/*
 *-----------------------------------------------------------------------------
 *
 * GaussianFilter01 --
 *
 *	Apply a Gaussian filter or one of its derivatives across the rows
 *	of an image.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	'outputImage' receives the filtered image.  'outputImage' should
 *	not be the same memory as 'inputImage'.
 *
 *------------------------------------------------------------------------------
 */

void
GaussianFilter01(
    GaussianFilterSet filterPtr,
				/* Filter to apply */
    int whichDeriv,		/* Which derivative to apply */
    int height,			/* Height of the images */
    int width,			/* Width of the images */
    float* inputImage,		/* Input image */
    float* outputImage		/* Output image */
) {
    int i;
    for (i = 0; i < height; ++i) {
	GaussianApplyFilter(filterPtr, whichDeriv, width,
			    inputImage + i * width, 1, 
			    outputImage + i * width, 1);
    }
}

/*
 *-----------------------------------------------------------------------------
 *
 * GaussianFilter10 --
 *
 *	Apply a Gaussian filter or one of its derivatives down the columns
 *	of an image.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	'outputImage' receives the filtered image.  'outputImage' should
 *	not be the same memory as 'inputImage'.
 *
 *------------------------------------------------------------------------------
 */

void
GaussianFilter10(
    GaussianFilterSet filterPtr,
				/* Filter to apply */
    int whichDeriv,		/* Which derivative to apply */
    int height,			/* Height of the images */
    int width,			/* Width of the images */
    float* inputImage,		/* Input image */
    float* outputImage		/* Output image */
) {
    int i;
    for (i = 0; i < width; ++i) {
	GaussianApplyFilter(filterPtr, whichDeriv, height,
			    inputImage + i, width, 
			    outputImage + i, width);
    }
}

/*
 *-----------------------------------------------------------------------------
 *
 * GaussianBlur2D --
 *
 *	Apply a Gaussian blur to an image.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	'outputImage' receives the blurred image. It is permissible for
 *	'outputImage' and 'inputImage' to occupy the same memory.	
 *
 *-----------------------------------------------------------------------------
 */

void
GaussianBlur2D(
    GaussianFilterSet filterPtr, 
				/* Filter to apply */
    int height,			/* Height of the images */
    int width,			/* Width of the images */
    float* inputImage,		/* Input image: (height x width) array of
				 * float's, row-major order */
    float* outputImage		/* Output image: (height x width) array of
				 * float's, row-major order */
) {
    int area = height * width;
    float* tempImage = (float*) ckalloc(area * sizeof(float));

    /* 
     * Filter first the rows and then the columns.
     */

    GaussianFilter01(filterPtr, 0, height, width, inputImage, tempImage);
    GaussianFilter10(filterPtr, 0, height, width, tempImage, outputImage);

    ckfree((char*)tempImage);
}

/*
 *-----------------------------------------------------------------------------
 *
 * GaussianGradientX2D --
 *
 *	Applies the derivative of a Gaussian filter along the X component
 *	(that is, along the second subscript) of a 2-d image.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Gradient vector's X component is placed in the output image. It is
 *	permissible for input and output to be the same image.
 *
 *-----------------------------------------------------------------------------
 */

void
GaussianGradientX2D(
    GaussianFilterSet filterPtr, 
				/* Filter to apply */
    int height,			/* Height of the images */
    int width,			/* Width of the images */
    float* inputImage,		/* Input image: (height x width) array of
				 * float's, row-major order */
    float* outputImage		/* Output image: (height x width) array of
				 * float's, row-major order */
) {
    int area = height * width;
    float* tempImage = (float*) ckalloc(area * sizeof(float));
    int i;

    /* 
     * Derivative-filter the rows.
     */

    GaussianFilter01(filterPtr, 1, height, width, inputImage, tempImage);

    /*
     * Gaussian-filter the columns
     */

    GaussianFilter10(filterPtr, 0, height, width, tempImage, outputImage);

    ckfree((char*)tempImage);
}

/*
 *-----------------------------------------------------------------------------
 *
 * GaussianGradientY2D --
 *
 *	Applies the derivative of a Gaussian filter along the Y component
 *	(that is, along the first subscript) of a 2-d image.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Gradient vector's Y component is placed in the output image. It is
 *	permissible for input and output to be the same image.
 *
 *-----------------------------------------------------------------------------
 */

void
GaussianGradientY2D(
    GaussianFilterSet filterPtr, 
				/* Filter to apply */
    int height,			/* Height of the images */
    int width,			/* Width of the images */
    float* inputImage,		/* Input image: (height x width) array of
				 * float's, row-major order */
    float* outputImage		/* Output image: (height x width) array of
				 * float's, row-major order */
) {
    int area = height * width;
    float* tempImage = (float*) ckalloc(area * sizeof(float));
    int i;

    /* 
     * Gaussian-filter the rows.
     */

    GaussianFilter01(filterPtr, 0, height, width, inputImage, tempImage);

    /*
     * Derivative-filter the columns
     */

    GaussianFilter10(filterPtr, 1, height, width, tempImage, outputImage);

    ckfree((char*)tempImage);
}

/*
 *-----------------------------------------------------------------------------
 *
 * GaussianGradientMagnitude2D --
 *
 *	Computes the magnitude of the gradient of a Gaussian filter
 *	applied to a 2-d image.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Gradient vector's magnitude is placed in the output image. It is
 *	permissible for input and output to occupy the same memory.
 *
 *-----------------------------------------------------------------------------
 */

void
GaussianGradientMagnitude2D(
    GaussianFilterSet filterPtr, 
				/* Filter to apply */
    int height,			/* Height of the images */
    int width,			/* Width of the images */
    float* inputImage,		/* Input image: (height x width) array of
				 * float's, row-major order */
    float* outputImage		/* Output image: (height x width) array of
				 * float's, row-major order */
) {
    int i;
    int area = height * width;
    float* tempImageX = (float*) ckalloc(area * sizeof(float));

    GaussianGradientX2D(filterPtr, height, width, inputImage, tempImageX);
    GaussianGradientY2D(filterPtr, height, width, inputImage, outputImage);
    for (i = 0; i < area; ++i) {
	outputImage[i] = hypotf(tempImageX[i], outputImage[i]);
    }
    ckfree((char*)tempImageX);
}

/*
 *-----------------------------------------------------------------------------
 *
 * GaussianLaplacian2D --
 *
 *	Computes the Laplacian of a Gaussian filter applied to a 2-d image.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Laplacian is placed in the output image. It is permissible for
 *	input and output to occupy the same memory.
 *
 *-----------------------------------------------------------------------------
 */

void
GaussianLaplacian2D(
    GaussianFilterSet filterPtr, 
				/* Filter to apply */
    int height,			/* Height of the images */
    int width,			/* Width of the images */
    float* inputImage,		/* Input image: (height x width) array of
				 * float's, row-major order */
    float* outputImage		/* Output image: (height x width) array of
				 * float's, row-major order */
) {
    int area = height * width;
    float* tempImage1 = (float*) ckalloc(area * sizeof(float));
    float* tempImage2 = (float*) ckalloc(area * sizeof(float));
    int i;

    /* Gaussian filter by rows */

    GaussianFilter01(filterPtr, 0, height, width, inputImage, tempImage1);

    /* Second-derivative-filter by columns */

    GaussianFilter10(filterPtr, 2, height, width, tempImage1, tempImage2);


    /* Second-derivative filter by rows */

    GaussianFilter01(filterPtr, 2, height, width, inputImage, tempImage1);

    /* Gaussian-filter by columns */

    GaussianFilter10(filterPtr, 0, height, width, tempImage1, outputImage);

    /* Sum the two results */

    for (i = 0; i < area; ++i) {
	outputImage[i] += tempImage2[i];
    }

    ckfree((char*)tempImage1);
    ckfree((char*)tempImage2);
}

/*
 *-----------------------------------------------------------------------------
 *
 * FIRInitFilterSet --
 *
 *	Initializes the data needed for the FIR implementation of the
 *	Gaussian derivative filter.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Initializes the filter state,
 *
 *-----------------------------------------------------------------------------
 */

static void
FIRInitFilterSet(
    FIRFilterSet* filterPtr,	/* Filter under construction */
    double sigma		/* Width of the filter */
) {
    /* 
     * Compute an appropriate filter width, and allocate memory for the filter.
     */

    int k = (sigma >= 0.5) ? (int)(4.5 * sigma) : 2;
				/* Half-width of the filter */
    int n = 2 * k + 1;		/* Size of the coefficient arrays */
    int i;
    float* gauss = (float*) ckalloc(n * sizeof(float));
    float* deriv = (float*) ckalloc(n * sizeof(float));
    float* deriv2 = (float*) ckalloc(n * sizeof(float));
    float intgauss = 0.0f, intderiv = 0.0f, intderiv2 = 0.0f;

    /*
     * Initialize the filters with a rough approximation. Calculate the
     * integrals of the kernels in preparation for correcting them.
     */

    for (i = 0; i <= k; ++i) {
	float low = i - 0.5f;
	float high = i + 0.5f;
	float t = (i / sigma);
	gauss[k - i] = gauss[k + i] = expf(-i * i / (2.0f * sigma * sigma))
	    / (sigma * sqrtf(2.0 * M_PI));
	intgauss += 2.0f * gauss[k-i];
	deriv[k + i] = 
	    (expf(-high * high / (2.0f * sigma * sigma))
	     - expf(-low * low / (2.0f * sigma * sigma)))
	    / (sigma * sqrtf(2.0 * M_PI));
	deriv[k - i] = -deriv[k + i];
	intderiv += 2.0f * deriv[k + i] * sinf(t);
	deriv2[k - i] = deriv2[k + i] =
	    (low * expf(-low * low / (2.0f * sigma * sigma))
	     - high * expf(-high * high / (2.0f * sigma * sigma)))
	    / (sigma * sigma * sigma * sqrtf(2.0 * M_PI));
	intderiv2 += cosf(t * sqrtf(2.0f)) * (2.0f * deriv2[k - i]);
    }

    /* 
     * Clean up center effects on the integrals, and scale them to unity. 
     */

    intgauss -= gauss[k];
    intderiv2 -= deriv2[k];
    intderiv *= sigma * exp(0.5);
    intderiv2 *= -(sigma * sigma) / (2.0 * expf(-1.0));

    /*
     * Adjust the coefficients so that the integrals have the correct values
     */

    gauss[k] /= intgauss;
    deriv[k] /= intderiv;
    deriv2[k] /= intderiv2;
    for (i = 1; i <= k; ++i) {
	gauss[k + i] /= intgauss;
	gauss[k - i] /= intgauss;
	deriv[k + i] /= intderiv;
	deriv[k - i] /= intderiv;
	deriv2[k + i] /= intderiv2;
	deriv2[k - i] /= intderiv2;
    }

    /*
     * Stash results in the filter data structure.
     */

    filterPtr->n = n;
    filterPtr->coefs[0] = gauss;
    filterPtr->coefs[1] = deriv;
    filterPtr->coefs[2] = deriv2;
}

/*
 *-----------------------------------------------------------------------------
 *
 * FIRApply --
 *
 *	Apply a FIR Gaussian derivative filter.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Convolution product appears in the 'y' array, which may not be the
 *	same memory as 'x'.
 *
 *-----------------------------------------------------------------------------
 */

static void
FIRApply(
    FIRFilterSet* filterPtr,
				/* Filter to apply */
    int whichDeriv,	        /* Which derivative [0..2] of the Gaussian
			         * to convolve */
    int n,		        /* Size of the input and output arrays */
    float* x,			/* Input function to smooth */
    int xStride,		/* Stride of the input array */
    float* y,			/* Output smoothed function */
    int yStride			/* Stride of the output array */
) {
    FIRConvolve(filterPtr->n, filterPtr->coefs[whichDeriv],
		n, x, xStride, y, yStride);
}

/*
 *-----------------------------------------------------------------------------
 *
 * FIRDestroyFilterSet --
 *
 *	Destroys the filter set created by FIRInitFilterSet
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	All system resources used by the filter set are freed.
 *
 *-----------------------------------------------------------------------------
 */

static void
FIRDestroyFilterSet(
    FIRFilterSet* filterPtr
) {
    ckfree((void*) (filterPtr->coefs[0]));
    ckfree((void*) (filterPtr->coefs[1]));
    ckfree((void*) (filterPtr->coefs[2]));
}

/*
 *-----------------------------------------------------------------------------
 *
 * DericheInitFilterSet --
 *
 *	Initializes the data needed for the Deriche implementation of the
 *	Gaussian derivative filter.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Initializes the filter state.
 *
 * Source:
 *	Deriche, Rachid. "Recirsuvely implementating the Gaussian and its 
 *	derivatives." Rapport de Recherche RR-1893, Sophia Antipolis, France:
 *	INRIA, April 1993.
 *
 *-----------------------------------------------------------------------------
 */

static void 
DericheInitFilterSet(
    DericheFilterSet* filterPtr,	
				/* Storage for filter coefficients */
    double sigma		/* Radius of the distribution */
) {

    /*
     * Constants computed using Deriche's method, but expanded to fill
     * double-precision floating point. See section 5 of the paper.
     */

    const static DerichePrecomputed precomp[] = {
	{			/* Gaussian */
	    1.6797292232361107, 3.7348298269103580,
	    1.7831906544515104, 1.7228297663338028,
	    -0.6802783501806897, -0.2598300478959625,
	    0.6318113174569493, 1.9969276832487770
	},
	{			/* Derivative of Gaussian */
	    0.6494024008440620, 0.9557370760729773,
	    1.5159726670750566, 1.5267608734791140,
	    -0.6472105276644291, -4.5306923044570760,
	    2.0718953658782650, 0.6719055957689513
	},
	{
	    0.3224570510072559, -1.7382843963561239,
	    1.3138054926516880,  1.2402181393295362,
	    -1.3312275593739595, 3.6607035671974897,
	    2.1656041357418863, 0.7479888745408682
	}
    };
    
    int i;

    /* 
     * Loop through the Gaussian and its first two derivatives, and
     * scale the filter coefficiencts.
     */

    for (i = 0; i < 3; ++i) {
	DericheInitCoefficients(i, filterPtr->coefs + i, precomp + i, sigma);
    }

    /*
     * Correct the scaling so as to yield the correct integrated magnitude.
     */

    DericheScaleN(filterPtr, sigma);
}

/*
 *-----------------------------------------------------------------------------
 *
 * DericheInitCoefficients --
 *
 *	Initialize the filter coefficients for a Deriche filter for the
 *	Gaussian or one of its derivatives.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Stores the coefficients in '*cPtr'.
 *
 *-----------------------------------------------------------------------------
 */

static void
DericheInitCoefficients(
    int i,			/* Which derivative? */
    DericheCoefficients* cPtr, 	/* Filter coefficients being prepared */
    const DerichePrecomputed* pPtr,
				/* Precomputed quantities for filter */
    double sigma		/* Radius of the distribution */
) {

    /* 
     * See section 5 of the paper for the derivation of these formulas. 
     */

    if (i % 2 == 0) {
	cPtr->n0 = pPtr->a0 + pPtr->c0;
    } else {
	cPtr->n0 = 0.0;
    }
    cPtr->n1 = 
	exp(-pPtr->b1/sigma) 
	    * (pPtr->c1*sin(pPtr->w1/sigma) 
	       - (pPtr->c0+2.0*pPtr->a0)*cos(pPtr->w1/sigma))
	+ exp(-pPtr->b0/sigma) 
	    * (pPtr->a1*sin(pPtr->w0/sigma) 
	       - (2.0*pPtr->c0+pPtr->a0)*cos(pPtr->w0/sigma));
    cPtr->n2 = 
	2.0*exp(-(pPtr->b0+pPtr->b1)/sigma) 
	    * ((pPtr->a0+pPtr->c0)*cos(pPtr->w1/sigma)*cos(pPtr->w0/sigma)
	       - pPtr->a1*cos(pPtr->w1/sigma)*sin(pPtr->w0/sigma)
	       - pPtr->c1*cos(pPtr->w0/sigma)*sin(pPtr->w1/sigma))
	+ pPtr->c0*exp(-2.0*pPtr->b0/sigma) 
	+ pPtr->a0*exp(-2.0*pPtr->b1/sigma);
    cPtr->n3 =
	exp(-(pPtr->b1+2.0*pPtr->b0)/sigma) 
	    * (pPtr->c1*sin(pPtr->w1/sigma) - pPtr->c0*cos(pPtr->w1/sigma))
	+ exp(-(pPtr->b0+2.0*pPtr->b1)/sigma) 
	    * (pPtr->a1*sin(pPtr->w0/sigma) - pPtr->a0*cos(pPtr->w0/sigma));
    cPtr->d1 =
	-2.0*exp(-pPtr->b0/sigma)*cos(pPtr->w0/sigma) 
	- 2.0*exp(-pPtr->b1/sigma)*cos(pPtr->w1/sigma);
    cPtr->d2 = 
	4.0*exp(-(pPtr->b0+pPtr->b1)/sigma) 
	    * cos(pPtr->w0/sigma) * cos(pPtr->w1/sigma) 
	+ exp(-2.0*pPtr->b0/sigma) 
	+ exp(-2.0*pPtr->b1/sigma);
    cPtr->d3 = 
	-2.0*exp(-(pPtr->b0+2.0*pPtr->b1)/sigma) * cos(pPtr->w0/sigma) 
	- 2.0*exp(-(pPtr->b1+2.0*pPtr->b0)/sigma) * cos(pPtr->w1/sigma);
    cPtr->d4 = exp(-2.0*(pPtr->b0+pPtr->b1)/sigma);
 
}

/*
 *-----------------------------------------------------------------------------
 *
 * DericheScaleN --
 *
 *	Scale the coefficients of a Deriche filter to yield the correct
 *	integrated magnitude.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Coefficients in *filterPtr are adjusted.
 *
 *-----------------------------------------------------------------------------
 */

static void
DericheScaleN(
    DericheFilterSet* filterPtr,
				/* Deriche filter under construction */
    double sigma		/* Width of the filter */
) {

    /* Construct temporary arrays that record the impulse response */

    int n = 1 + 2 * (int)(10.0 * sigma);
				/* Size of each temporary array */
    int m = (n - 1) / 2;	/* Midpoint of each temporary array */
    float* x = (float*) ckalloc(n * sizeof(float));
				/* Unit impulse */
    float* y0 = (float*) ckalloc(n * sizeof(float));
				/* Impulse response of the unscaled Gaussian */
    float* y1 = (float*) ckalloc(n * sizeof(float));
				/* Impulse response of the unscaled Gaussian
				 * derivative */
    float* y2 = (float*) ckalloc(n * sizeof(float));
				/* Impulse response of the unscaled Gaussian
				 * second derivative */

    double s[3] = {0.0, 0.0, 0.0};
    int i, j;
    
    /* 
     * Let x be the unit impulse 
     */

    memset(x, 0, n * sizeof(float));
    x[m] = 1.0f;

    /* 
     * Apply the filters for Gaussian and its first two derivatives to the
     * unit impulse. 
     */

    DericheApply(filterPtr, 0, n, x, 1, y0, 1, sigma);
    DericheApply(filterPtr, 1, n, x, 1, y1, 1, sigma);
    DericheApply(filterPtr, 2, n, x, 1, y2, 1, sigma);

    /* 
     * Integrate gaussian, sin(t)*gradient, cos(t sqrt(2))*laplacian
     */

    for (i = 0, j = n-1; i < j; ++i, --j) {
	double t = (i - m) / sigma;
	s[0] += y0[j] + y0[i];
	s[1] += sin(t) * (y1[j] - y1[i]);
	s[2] += cos(t * sqrt(2.0)) * (y2[j] + y2[i]);
    }

    /* 
     * Fix up the midpoints and normalize the integrals 
     */

    s[0] += y0[m];
    s[2] += y2[m];
    s[1] *= sigma * exp(0.5);
    s[2] *= -(sigma*sigma) / 2.0 * exp(1.0);

    /* 
     * Scale the filter to give the correct integrals
     */

    for (i = 0; i < 3; ++i) {
	filterPtr->coefs[i].n0 /= s[i];
	filterPtr->coefs[i].n1 /= s[i];
	filterPtr->coefs[i].n2 /= s[i];
	filterPtr->coefs[i].n3 /= s[i];
    }

    ckfree((char*)y2);
    ckfree((char*)y1);
    ckfree((char*)y0);
    ckfree((char*)x);
}

/*
 *-----------------------------------------------------------------------------
 *
 * DericheApply --
 *
 *	Convolves a function with a Gaussian derivative, using Deriche's
 *	method.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Convolution product appears in the 'y' array, which may not be the
 *	same memory as 'x'.
 *
 *-----------------------------------------------------------------------------
 */

static void
DericheApply(
    DericheFilterSet* filterPtr,
				/* Filter to apply */
    int whichDeriv,	        /* Which derivative [0..2] of the Gaussian
			         * to convolve */
    int n,		        /* Size of the input and output arrays */
    float* x,			/* Input function to smooth */
    int xStride,		/* Stride of the input array */
    float* y,			/* Output smoothed function */
    int yStride,		/* Stride of the output array */
    double sigma		/* Radius of the filter */
) {
    DericheCoefficients* cPtr = filterPtr->coefs + whichDeriv;
				/* Filters to apply */
    
    /* Unpack the filter coefficients */

    float n0 = cPtr->n0, n1 = cPtr->n1, n2 = cPtr->n2, n3 = cPtr->n3, n4;
    float d1 = cPtr->d1, d2 = cPtr->d2, d3 = cPtr->d3, d4 = cPtr->d4;

    float yim4 = 0.0f, yim3 = 0.0f, yim2 = 0.0f, yim1 = 0.0f;
    float xim3 = 0.0f, xim2 = 0.0f, xim1 = 0.0f;

    float yip4 = 0.0f, yip3 = 0.0f, yip2 = 0.0f, yip1 = 0.0f;
    float xip4 = 0.0f, xip3 = 0.0f, xip2 = 0.0f, xip1 = 0.0f;

    int prime;			/* Size of support used to "prime the
				 * pump" to approximate a Cauchy boundary */

    int i;

    /* 
     * Compute support size for preconditioning the filter 
     */

    prime = (int)(4.0 * sigma);
    if (prime >= n) prime = n-1;

    /* 
     * Run the 4th-order filter in the right-to-left direction at the
     * left edge of the image to 'prime the pump', approximating a
     * Cauchy boundary.
     */

    for (i = prime; i > 0; --i) {
	float xi = x[i * xStride];
	float yi = n0 * xi + n1 * xim1 + n2 * xim2 + n3 * xim3
	    - d1 * yim1 - d2 * yim2 - d3 * yim3 - d4 * yim4;
	yim4 = yim3; yim3 = yim2; yim2 = yim1; yim1 = yi;
	xim3 = xim2; xim2 = xim1; xim1 = xi;
    }

    /* Run the 4th-order filter in the left-to-right direction */

    for (i = 0; i < n; ++i) {
	float xi = x[i * xStride];
	float yi = n0 * xi + n1 * xim1 + n2 * xim2 + n3 * xim3
	    - d1 * yim1 - d2 * yim2 - d3 * yim3 - d4 * yim4;
	y[i * yStride] = yi;
	yim4 = yim3; yim3 = yim2; yim2 = yim1; yim1 = yi;
	xim3 = xim2; xim2 = xim1; xim1 = xi;
    }

    /* Adjust coefficients for the right-to-left direction */

    n1 -= d1 * n0; n2 -= d2 * n0; n3 -= d3 * n0; n4 = - d4 * n0;
    if (whichDeriv % 2) {
	n1 = -n1; n2 = -n2; n3 = -n3; n4 = -n4;
    }

    /* 
     * 'Prime the pump' again
     */

    for (i = n - prime; i+1 < n; ++i) {
	float xi = x[i * xStride];
	float yi = n1 * xip1 + n2 * xip2 + n3 * xip3 + n4 * xip4
	    - d1 * yip1 - d2 * yip2 - d3 * yip3 - d4 * yip4;
	xip4 = xip3; xip3 = xip2; xip2 = xip1; xip1 = xi;
	yip4 = yip3; yip3 = yip2; yip2 = yip1; yip1 = yi;
    }

    /* Run the 4th-order filter in the right-to-left direction */

    for (i = n-1; i >= 0; --i) {
	float xi = x[i * xStride];
	float yi = n1 * xip1 + n2 * xip2 + n3 * xip3 + n4 * xip4
	    - d1 * yip1 - d2 * yip2 - d3 * yip3 - d4 * yip4;
	y[i * yStride] += yi;
	xip4 = xip3; xip3 = xip2; xip2 = xip1; xip1 = xi;
	yip4 = yip3; yip3 = yip2; yip2 = yip1; yip1 = yi;
    }
}

/*
 *-----------------------------------------------------------------------------
 *
 * VanVlietInitFilterSet --
 *
 *	Initializes a set of filters to evaluate Gaussian and its derivatives.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Initializes the filter coefficients for the Gaussian and its first
 *	two derivatives.
 *
 * Sources:
 *	van Vliet, Lucas J.; Young, Ian T.; Verbeek, Piet W.  "Recursive
 *	Gaussian derivative filters." Proc. 14th Intl. Conf. on Pattern
 *	Recognition.  Brisbane, Qld, Australia: IEEE, August 1998, vol. 1,
 *	pp. 509-514.
 *
 *	Hale, Dave. "Recursive Gaussian Filters." Technical Report CWP-546,
 *	Golden, Colorado: Center for Wave Phenomena, Colorado School of Mines,
 *	http://www.cwp.mines.edu/Meetings/Project06/cwp546.pdf, retrieved 
 *	6 April 2011.
 *
 *
 * See section 3.3 of the Hale paper for a discussion of this calculation,
 * which uses the method of partial fractions to separate the serial
 * (all-poles) implementation into a parallel (poles-and-zeroes)
 * implementation.
 *
 *-----------------------------------------------------------------------------
 */

static void
VanVlietInitFilterSet(
    VanVlietFilterSet* filterPtr,
				/* Filter set under construction */
    double sigma		/* Width of the filter */
) {

    /* 
     * Poles of the L[infinity]-residual filter, 4th order, from Tables
     * 1 and 2 of the van Vliet paper. 
     */

    const static doublecomplex VVpoles[3][4] = {
	/* Gaussian */
	{ { 1.12075,  1.27788 }, { 1.12075, -1.27788 },
	  { 1.76952,  0.46611 }, { 1.76952, -0.46611 } },
	/* First derivative of Gaussian */
	{ { 1.04185,  1.24034 }, { 1.04185, -1.24034 },
	  { 1.69747,  0.44790 }, { 1.69747, -0.44790 } },
	/* Second derivative of Gaussian */
	{ { 0.94570,  1.21064 }, { 0.94570, -1.21064 },
	  { 1.60161,  0.42647 }, { 1.60161, -0.42647 } } 
    };

    int i;			/* Which derivative? */
    doublecomplex poles[4];	/* Pole locations after scaling for sigma */
    double gain;		/* Filter gain */
    double gg;			/* Square of gain */
    doublecomplex d0, d1, e0, e1, g0, g1;
    double a10, a11, a20, a21, b00, b01, b10, b11, b20, b21;

    /* 
     * Make filters for Gaussian, first derivative, second derivative 
     */

    for (i = 0; i < 3; ++i) {
	VanVlietAdjustPoles(VVpoles[i], sigma, poles);
	gain = VanVlietComputeGain(poles);
	gg = gain * gain;
	d0 = poles[0];
	d1 = poles[2];
	z_recip(&e0, &d0);
	z_recip(&e1, &d1);
	VanVlietResidue(i, &d0, poles, gg, &g0);
	VanVlietResidue(i, &d1, poles, gg, &g1);
	a10 = -2.0 * d0.r;
	a11 = -2.0 * d1.r;
	a20 = d0.r*d0.r + d0.i*d0.i;
	a21 = d1.r*d1.r + d1.i*d1.i;
	if (i % 2 == 0) {
	    b10 = g0.i / e0.i;
	    b11 = g1.i / e1.i;
	    b00 = g0.r - b10 * e0.r;
	    b01 = g1.r - b11 * e1.r;
	    b20 = 0.0;
	    b21 = 0.0;
	    RecursiveOrder2Init(&filterPtr->coefs[i][VVP_PASS1][VVD_FORWARD],
				b00, b10, b20, a10, a20);
	    RecursiveOrder2Init(&filterPtr->coefs[i][VVP_PASS2][VVD_FORWARD],
				b01, b11, b21, a11, a21);
	    b20 -= b00 * a20;
	    b21 -= b01 * a21;
	    b10 -= b00 * a10;
	    b11 -= b01 * a11;
	    b00 = 0.0;
	    b01 = 0.0;
	    RecursiveOrder2Init(&filterPtr->coefs[i][VVP_PASS1][VVD_REVERSE],
				b00, b10, b20, a10, a20);
	    RecursiveOrder2Init(&filterPtr->coefs[i][VVP_PASS2][VVD_REVERSE],
				b01, b11, b21, a11, a21);
	} else {
	    b20 = g0.i / e0.i;
	    b21 = g1.i / e1.i;
	    b10 = g0.r - b20 * e0.r;
	    b11 = g1.r - b21 * e1.r;
	    b00 = 0.0;
	    b01 = 0.0;
	    RecursiveOrder2Init(&filterPtr->coefs[i][VVP_PASS1][VVD_FORWARD],
				b00, b10, b20, a10, a20);
	    RecursiveOrder2Init(&filterPtr->coefs[i][VVP_PASS2][VVD_FORWARD],
				b01, b11, b21, a11, a21);
	    b20 = -b20;
	    b21 = -b21;
	    b10 = -b10;
	    b11 = -b11;
	    b00 = 0.0;
	    b01 = 0.0;
	    RecursiveOrder2Init(&filterPtr->coefs[i][VVP_PASS1][VVD_REVERSE],
				b00, b10, b20, a10, a20);
	    RecursiveOrder2Init(&filterPtr->coefs[i][VVP_PASS2][VVD_REVERSE],
				b01, b11, b21, a11, a21);
	}
    }
}

/*
 *-----------------------------------------------------------------------------
 *
 * VanVlietAdjustPoles --
 *
 *	Rescales the pole positions of a Van Vliet filter to achieve the
 *	desired standard deviation.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Sets 'scaled' to the scaled pole locations.
 *
 *-----------------------------------------------------------------------------
 */

static void
VanVlietAdjustPoles(
    const doublecomplex unscaled[4],
				/* Unscaled pole locations from Table 1 or
				 * 2 of the paper. */
    double sigma,		/* Standard deviation */
    doublecomplex scaled[4]	/* Scaled pole locations */
) {
    double q = sigma;
				/* Scale factor */
    int iter;			/* Iteration number */
    double s = VanVlietComputeSigma(q, unscaled);
    int i;

    /* Search for a scale factor q that yields the desiged sigma. */

    for (iter = 0; fabs(sigma-s) > sigma * 1.0e-8; ++iter) {
	s = VanVlietComputeSigma(q, unscaled);
	q *= sigma/s;
    }

    /* Adjust poles */

    for (i = 0; i < 4; ++i) {
	doublecomplex pi = unscaled[i];
	double a = pow(z_abs(&pi), 2.0 / q);
	double t = atan2(pi.i, pi.r) * 2.0 / q;
	scaled[i].r = 1.0/a * cos(t); scaled[i].i = -1.0/a * sin(t);
    }
}

/*
 *-----------------------------------------------------------------------------
 *
 * VanVlietComputeSigma --
 *
 *	Compute tha actual standard deviation of a Van Vliet filter.
 *
 * Results:
 *	Returns the computed standard deviation.
 *
 *-----------------------------------------------------------------------------
 */

static double
VanVlietComputeSigma(
    double sigma,		/* Scale factor */
    const doublecomplex poles[4]
				/* Poles of the filter */
) {
    double q = sigma / 2.0;
    doublecomplex cs = {0.0, 0.0};
    doublecomplex b, c, d, temp;
    int i;
    for (i = 0; i < 4; ++i) {
	doublecomplex pi = poles[i];
	double a = pow(z_abs(&pi), -1.0 / q);
	double t = atan2(pi.i, pi.r) / q;
	b.r = a * cos(t); b.i = a * sin(t);
	c.r = 1.0 - b.r; c.i = - b.i;
	d.r = c.r * c.r - c.i * c.i; d.i = 2.0 * c.r * c.i;
	b.r *= 2.0; b.i *= 2.0;
	z_div(&temp, &b, &d);
	cs.r += temp.r; cs.i += temp.i;
    }
    return sqrt(cs.r);
}

/*
 *-----------------------------------------------------------------------------
 *
 * VanVlietComputeGain --
 *
 *	Computes the gain of a Van Vliet filter.
 *
 * Results:
 *	Returns the computed gain.
 *
 *-----------------------------------------------------------------------------
 */

static double
VanVlietComputeGain(
    const doublecomplex poles[4]
				/* Poles of the filter */
) {
    int i;
    doublecomplex gain = {1.0, 0.0};
    doublecomplex temp;
    for (i = 0; i < 4; ++i) {
	temp.r = gain.r * (1.0 - poles[i].r) + gain.i * poles[i].i;
	temp.i = gain.r * (- poles[i].i) + gain.i * (1.0 - poles[i].r);
	gain.r = temp.r;
	gain.i = temp.i;
    }
    return gain.r;
}

/*
 *-----------------------------------------------------------------------------
 *
 * VanVlietResidue --
 *
 *	Computes constant term of a Van Vliet filter.
 *
 * Results:
 *	Stores the constant term in '*residue'
 *
 * See section 3.3 of the Hale paper for a discussion of this calculation,
 * which uses the method of partial fractions to separate the serial
 * (all-poles) implementation into a parallel (poles-and-zeroes)
 * implementation.
 *
 *-----------------------------------------------------------------------------
 */
 
static void
VanVlietResidue(
    int whichDeriv,		/* Which derivative are we evaluating */
    const doublecomplex* polej,	/* Which pole are we computing for */
    const doublecomplex poles[4],
				/* Poles of the filter */
    double gain,		/* Gain of the filter */
    doublecomplex* residue	/* Output: Computed residue */
) {
    doublecomplex pi;
    doublecomplex pj = *polej;
    doublecomplex qj;
    doublecomplex gz = {1.0, 0.0};
    doublecomplex gp = {1.0, 0.0};
    doublecomplex temp, temp2;
    int i;
    z_recip(&qj, &pj);
    if (whichDeriv == 1) {
	temp.r = (1.0 - qj.r) * gz.r + qj.i * gz.i;
	temp.i = (1.0 - qj.r) * gz.i - qj.i * gz.r; /* gz * (1-qj) */
	gz = temp;
	temp.r = (1.0 + pj.r) * gz.r - pj.i * gz.i;
	temp.i = (1.0 + pj.r) * gz.i + pj.i * gz.r; /* gz * (1+pj) */
	gz = temp;
	temp.r = pj.r * gz.r - pj.i * gz.i; /* gz * pj */
	temp.i = pj.r * gz.i + pj.i * gz.r;
	gz.r = 0.5 * temp.r; gz.i = 0.5 * temp.i;
    } else if (whichDeriv == 2) {
	temp.r = (1.0 - qj.r) * gz.r + qj.i * gz.i;
	temp.i = (1.0 - qj.r) * gz.i - qj.i * gz.r; /* gz * (1 - qj) */
	gz = temp;
	temp.r = (1.0 - pj.r) * gz.r + pj.i * gz.i;
	temp.i = (1.0 - pj.r) * gz.i - pj.i * gz.r; /* gz * (1 - pj) */
	gz.r = -temp.r; gz.i = -temp.i;
    }
    for (i = 0; i < 4; ++i) {
	pi = poles[i];
	if ((pi.r != pj.r) || (pi.i != pj.i && pi.i != -pj.i)) {
	    temp.r = 1.0 - pi.r * qj.r + pi.i * qj.i;
	    temp.i = - pi.r * qj.i - pi.i * qj.r; /* 1 - pi * qj */
	    temp2.r = gp.r * temp.r - gp.i * temp.i;
	    temp2.i = gp.i * temp.r + gp.r * temp.i; /* gp * (1 - pi * qj) */
	    gp = temp2;
	}
	temp.r = 1.0 - pi.r * pj.r + pi.i * pj.i;
	temp.i = -pi.r * pj.i - pi.i * pj.r; /* 1 - pi * pj */
	temp2.r = gp.r * temp.r - gp.i * temp.i;
	temp2.i = gp.i * temp.r + gp.r * temp.i; /* gp * (1 - pi * pj) */
 	gp = temp2;
    }
    z_div(&temp, &gz, &gp); /* gz / gp */
    residue->r = gain * temp.r;
    residue->i = gain * temp.i; /* gain * gz/gp */
}

/*
 *-----------------------------------------------------------------------------
 *
 * VanVlietApply --
 *
 *	Applies a van Vliet filter to an input function.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	'y' array is filled with the output function. 'y' may not be the
 *	same memory as 'x'.
 *
 *-----------------------------------------------------------------------------
 */ 
static void
VanVlietApply(
    VanVlietFilterSet* filters,	/* Filter set  */
    int whichDerivative,	/* Which derivative are we applying? */
    int n,			/* Size of the input and output arrays */
    float* x,			/* Array containing the input function */
    int xStride,		/* Stride of the input array */
    float* y,			/* Array containing the output function */
    int yStride,		/* Stride of the output array */
    double sigma		/* Standard deviation of the Gaussian */
) {

    /* 
     * Develop a radius of 4 sigma to "prime the pump" to approximate
     * a Cauchy boundary condition at the edge of the image.
     */

    int prime = (int)(4.0 * sigma);
    if (prime > n) {
	prime = n;
    }
    
    /* Apply the cascaded second-order filters forward and backward. */

    RecursiveOrder2ApplyForward
	(&filters->coefs[whichDerivative][VVP_PASS1][VVD_FORWARD],
	 n, prime, x, xStride, y, yStride);    
    RecursiveOrder2AccumulateReverse
	(&filters->coefs[whichDerivative][VVP_PASS1][VVD_REVERSE],
	 n, prime, x, xStride, y, yStride);
    RecursiveOrder2AccumulateForward
	(&filters->coefs[whichDerivative][VVP_PASS2][VVD_FORWARD],
	 n, prime, x, xStride, y, yStride);    
    RecursiveOrder2AccumulateReverse
	(&filters->coefs[whichDerivative][VVP_PASS2][VVD_REVERSE],
	 n, prime, x, xStride, y, yStride);
}
