/*
 * map_scalar.c --
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

#define MAPNAME2(IN,OUT) crimp_piecewise_linear_map_ ## IN ## _ ## OUT
#define MAPNAME(IN,OUT) MAPNAME2(IN,OUT)

#define NEWNAME2(OUT) crimp_new_ ## OUT ## _at
#define NEWNAME(OUT) NEWNAME2(OUT)

#define STRINGIZE2(NAME) #NAME
#define STRINGIZE(NAME) STRINGIZE2(NAME)

crimp_image* resultImage;

resultImage = NEWNAME(OUTTYPENAME)(crimp_x (image), crimp_y (image),
				   crimp_w (image), crimp_h (image));

if (MAPNAME(INTYPENAME,OUTTYPENAME)(interp,
				    mapObj,
				    (size_t) (crimp_w (image) * crimp_h (image)),
		                    (const INTYPE*)image->pixel, 
                                    (size_t) 1,
				    (OUTTYPE*)resultImage->pixel, 
                                    (size_t) 1)
    != TCL_OK) {
    return NULL;
}

return resultImage;

#undef STRINGIZE
#undef STRINGIZE2

#undef NEWNAME
#undef NEWNAME2

#undef MAPNAME
#undef MAPNAME2

