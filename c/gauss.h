/*
 * gauss.h --
 *
 *	Management of Gaussian derivative filters
 *
 * Copyright (c) 2011 by Kevin B. Kenny.
 *
 * See the file "license.terms" for information on usage and redistribution of
 * this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 *-----------------------------------------------------------------------------
 */

/*
 * Data structure that contains filter coefficients for Gaussian,
 * derivative-of-Gaussian, and Laplacian-of-Gaussian filters.
 */

typedef struct GaussianFilterSet_* GaussianFilterSet;

/* Functions for operating with Gaussian filters */

extern GaussianFilterSet GaussianCreateFilter(double);
				/* Create a set of Gaussian filters */
extern void GaussianApplyFilter(GaussianFilterSet, int, int,
				float*, int, float*, int);
				/* Apply a Gaussian filter or one
				 * of its derivatives to a
				 * vector of data. */
extern void GaussianDeleteFilter(GaussianFilterSet);
				/* Delete a set of Gaussian filters */
extern void GaussianBlur2D(GaussianFilterSet, int, int, float*, float*);
				/* Apply a Gaussian filter to a 2-d function */
extern void GaussianGradientX2D(GaussianFilterSet, int, int, float*, float*);
				/* Apply a Gaussian gradient
				 * to a 2-d function in the X direction */
extern void GaussianGradientY2D(GaussianFilterSet, int, int, float*, float*);
				/* Apply a Gaussian gradient to a 2-d function 
				 * in the Y direction*/
extern void GaussianGradientMagnitude2D(GaussianFilterSet, int, int, float*, 
					float*);
				/* Compute magnitude of the gradient
				 * vector in a Gaussian-filtered image */
extern void GaussianLaplacian2D(GaussianFilterSet, int, int, float*, 
				float*);
				/* Compute Laplacian of a Gaussian-filtered
				 * image */
