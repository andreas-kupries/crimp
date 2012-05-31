{
    /*
     * Border expansion core.
     *
     * Define the macros FILL, FILL_{NW,N,NE,W,E,SW,S,SE} and COPY before
     * including this file.
     */

    crimp_image* result;
    int          xo, yo, xi, yi;

    if ((ww < 0) || (hn < 0) || (we < 0) || (hs < 0)) {
	Tcl_SetResult(interp, "bad image border size, expected non-negative values", TCL_STATIC);
	return TCL_ERROR;
    }

    result = crimp_new_at (image->itype, 
			   crimp_x (image) - ww,
			   crimp_y (image) - hn,
			   crimp_w (image) + ww + we,
			   crimp_h (image) + hn + hs);

    /*
     * Nine quadrants to fill:
     *
     * NW N NE
     *  W C E
     * SW S SE
     *
     * The center block is the original image.
     */

#ifndef FILL_NW
#define FILL_NW(x,y) FILL(x,y)
#endif

#ifndef FILL_N
#define FILL_N(x,y) FILL(x,y)
#endif

#ifndef FILL_NE
#define FILL_NE(x,y) FILL(x,y)
#endif

#ifndef FILL_W
#define FILL_W(x,y) FILL(x,y)
#endif

#ifndef FILL_E
#define FILL_E(x,y) FILL(x,y)
#endif

#ifndef FILL_SW
#define FILL_SW(x,y) FILL(x,y)
#endif

#ifndef FILL_S
#define FILL_S(x,y) FILL(x,y)
#endif

#ifndef FILL_SE
#define FILL_SE(x,y) FILL(x,y)
#endif

    /*
     * North West.
     */

    if (hn && ww) {
	for (yo = 0; yo < hn; yo++) {
	    for (xo = 0; xo < ww; xo++) {
		FILL_NW (xo, yo);
	    }
	}
    }

    /*
     * North.
     */

    if (hn) {
	for (yo = 0; yo < hn; yo++) {
	    for (xo = 0; xo < crimp_w (image); xo++) {
		FILL_N (xo + ww, yo);
	    }
	}
    }

    /*
     * North East.
     */

    if (hn && we) {
	for (yo = 0; yo < hn; yo++) {
	    for (xo = 0; xo < we; xo++) {
		FILL_NE (xo + crimp_w (image) + ww, yo);
	    }
	}
    }

    /*
     * West.
     */

    if (ww) {
	for (xo = 0; xo < ww; xo++) {
	    for (yo = 0; yo < crimp_h (image); yo++) {
		FILL_W (xo, yo + hn);
	    }
	}
    }

    /*
     * East.
     */

    if (we) {
	for (xo = 0; xo < we; xo++) {
	    for (yo = 0; yo < crimp_h (image); yo++) {
		FILL_E (xo + crimp_w (image) + ww, yo + hn);
	    }
	}
    }

    /*
     * South West.
     */

    if (hs && ww) {
	for (yo = 0; yo < hs; yo++) {
	    for (xo = 0; xo < ww; xo++) {
		FILL_SW (xo, yo + crimp_h (image) + hn);
	    }
	}
    }

    /*
     * South.
     */

    if (hs) {
	for (yo = 0; yo < hs; yo++) {
	    for (xo = 0; xo < crimp_w (image); xo++) {
		FILL_S (xo + ww, yo + crimp_h (image) + hn);
	    }
	}
    }

    /*
     * South East.
     */

    if (hs && we) {
	for (yo = 0; yo < hs; yo++) {
	    for (xo = 0; xo < we; xo++) {
		FILL_SE (xo + crimp_w (image) + ww, yo + crimp_h (image) + hn);
	    }
	}
    }

    /*
     * Central. Copy of the input image.
     */

    for (yo = hn, yi = 0; yi < crimp_h (image); yo++, yi++) {
	for (xo = ww, xi = 0; xi < crimp_w (image); xo++, xi++) {
	    COPY (xo, yo, xi, yi);
	}
    }

    Tcl_SetObjResult(interp, crimp_new_image_obj (result));
    return TCL_OK;

#undef COPY
#undef FILL
#undef FILL_NW
#undef FILL_N
#undef FILL_NE
#undef FILL_W
#undef FILL_E
#undef FILL_SW
#undef FILL_S
#undef FILL_SE
}

/* vim: set sts=4 sw=4 tw=80 et ft=c: */
/*
 * Local Variables:
 * mode: c
 * c-basic-offset: 4
 * fill-column: 78
 * End:
 */
