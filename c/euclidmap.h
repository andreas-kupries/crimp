/*
 * euclimap.h --
 *
 *	Definitions of functions for euclidean distance maps
 *	Companion to Kevin's euclidmap.c
 *
 * Copyright (c) 2016 Andreas Kupries
 *
 * See the file "license.terms" for information on usage and redistribution of
 * this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 *-----------------------------------------------------------------------------
 */

extern void EuclideanDistanceMap1D (int n, const float* f, int stride, float* dist);
extern void EuclideanDistanceMap2D (int height, int width, const float* f, float* dist);
