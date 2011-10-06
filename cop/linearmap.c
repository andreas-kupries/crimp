/*
 * linearmap.c --
 *
 *	Template for a linear map/LUT operation on arbitrary data.
 *
 * Copyright (c) 2011 by Kevin B. Kenny
 *
 * See the file "license.terms" for information on usage and redistribution of
 * this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 *-----------------------------------------------------------------------------
 */

/*
 * This file must be included in a larger program and is intended to
 * specialize the procedure for a given data type.  Prior to including
 * it, the program must have the following definitions.
 *
 * #include <tcl.h>
 * #include <stdlib.h>
 * #define ITYPENAME float
 * #define ITYPE     float
 * #define OTYPENAME grey8
 * #define OTYPE     unsigned char
 * (or whatever types are appropriate to the current instance)
 */

#include "linearmaps.h"

/* 
 * The double substitution in FNAME/FNAME2 allows concatenation of
 * substituted parameters.
 */

#define FNAME2(name, intype, outtype) name ## _ ## intype ## _ ## outtype
#define FNAME(name, intype, outtype) FNAME2(name,intype,outtype)
#define SNAME2(name, intype) name ## _ ## intype
#define SNAME(name, intype) SNAME2(name,intype)
#define STRINGIZE2(word) #word
#define STRINGIZE(word) STRINGIZE2(word)

/*
 *-----------------------------------------------------------------------------
 *
 * UnpackData --
 *
 *	Unpacks a Tcl_Obj into a specification of input and output values
 *	for the mapping operation.
 *
 * Results:
 *	Returns TCL_OK if successful; leaves a message in the interpreter
 *	and returns TCL_ERROR on failure.
 *
 * Side effects:
 *	Stores pointers to the arrays of abscissae and ordinates in *xPtr
 *	and *yPtr, respectively, and the common size of the array in *nPtr.
 *	The pointers need not be freed (they are obtained from the byte
 *	array representation of the elements of 'mapObj', but 'mapObj' must
 *	not be shimmered while the arrays are in use.
 *
 *-----------------------------------------------------------------------------
 */

static int
FNAME(UnpackData,ITYPENAME,OTYPENAME) (
   Tcl_Interp* interp,	        /* Tcl interpreter for error reporting */
   Tcl_Obj* mapObj,		/* Tcl object containing the packed map */
   size_t* nPtr,		/* Pointer to the count of elements */
   const ITYPE** xPtr,		/* Pointer to the array of abscissae */
   const OTYPE** yPtr		/* Pointer to the array of ordinates */
) {
    int n;
    int length;
    const unsigned char* bytes;
    Tcl_Obj** parts;

    /* Take the map object apart into abscissa and ordinate. */

    if (Tcl_ListObjGetElements(interp, mapObj, &n, &parts) != TCL_OK) {
	return TCL_ERROR;
    }
    if (n != 2) {
	if (interp != NULL) {
	    Tcl_SetObjResult(interp,
			     Tcl_NewStringObj("map must be a 2-element list",
					      -1));
	    Tcl_SetErrorCode(interp, "CRIMP", "WRONGDATA", "2ELEMENTLIST",
			     NULL);
	}
	return TCL_ERROR;
    }

    /* Get the binary data for the abscissae */

    bytes = Tcl_GetByteArrayFromObj(parts[0], &n);
    if (n % sizeof(ITYPE) != 0) {
	if (interp != NULL) {
	    Tcl_SetObjResult(interp,
			     Tcl_NewStringObj("first element of map must be a "
					      "binary array of " 
					      STRINGIZE(ITYPENAME),
					      -1));
	    Tcl_SetErrorCode(interp, "CRIMP", "WRONGDATA", "ARRAYOF",
                             STRINGIZE(ITYPENAME), NULL);
	}
	return TCL_ERROR;
    }
    *xPtr = (const ITYPE*) bytes;
    *nPtr = n / sizeof(ITYPE);

    /* Get the binary data for the ordinates */

    bytes = Tcl_GetByteArrayFromObj(parts[1], &n);
    if (n != *nPtr * sizeof(OTYPE)) {
	if (interp != NULL) {
	    Tcl_SetObjResult(interp,
			     Tcl_NewStringObj("input and output arrays of map "
					      "must have equal size", -1));
	    Tcl_SetErrorCode(interp, "CRIMP", "WRONGDATA", "EQUALSIZEARRAY", 
			     NULL);
	}
	return TCL_ERROR;
    }
    *yPtr = (const OTYPE*) bytes;
    return TCL_OK;
}

/*
 *-----------------------------------------------------------------------------
 *
 * crimp_piecewise_linear_map_XXX_YYY --
 *
 *	Implements a mapping of an array of data from type XXX to type YYY
 *	using a piecewise linear function.
 *
 * Results:
 *	Returns TCL_OK if successful, TCL_ERROR (with a message in the
 *	interpreter) on failure.
 *
 * Side effects:
 *	Stores the mapped values in 'outpixels', placing the values every
 *	'outstride' elements.
 *
 *-----------------------------------------------------------------------------
 */

int
FNAME(crimp_piecewise_linear_map,ITYPENAME,OTYPENAME) (
    Tcl_Interp* interp,		/* Tcl interpreter */
    Tcl_Obj* mapObj,		/* Map to apply */
    size_t area,		/* Area of the image being mapped */
    const ITYPE* pixels,	/* Pixels of the image being mapped */
    size_t stride,		/* Stride (in pixel-sized units) of
				 * the elements (used for RGB/ARGB/HSV) */
    OTYPE* outpixels,		/* Pixels of the output image */
    size_t outstride		/* Stride (in pixel-sized units) of the
				 * elements of the output image */
) {

    const ITYPE* x;		/* Abscissae of the map */
    const OTYPE* y;		/* Ordinates of the map */
    size_t n;			/* Size of the map */
    ITYPE inpixel;		/* An input pixel */
    OTYPE outpixel;
    int i;			/* Pixel index */
    int j;			/* Index in the map of the target
				 * element for interpolation */

    /* Unpack the mapping table */

    if (FNAME(UnpackData,ITYPENAME,OTYPENAME)(interp, mapObj, &n, &x, &y)
	!= TCL_OK) {
	return TCL_ERROR;
    }

    /* Map the data */

    for (i = 0; i < area; ++i) {
	inpixel = pixels[i * stride];
	j = SNAME(crimp_binarysearch,ITYPENAME)(x, n, inpixel);
	if (j < 0) {
	    outpixel = y[0];
	} else if (j+1 >= n) {
	    outpixel = y[n-1];
	} else if (inpixel == x[j]) {
	    outpixel = y[j];
	} else {
	    outpixel = ((inpixel - x[j]) * y[j+1] + (x[j+1] - inpixel) * y[j])
		/ (x[j+1] - x[j]);
	}
	outpixels[i * outstride] = outpixel;
    }
    return TCL_OK;
	    
}

#undef FNAME
#undef FNAME2
#undef SNAME
#undef SNAME2
