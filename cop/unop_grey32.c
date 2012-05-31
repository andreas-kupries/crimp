/* x, y, w, h - Parameters of the output image. Provided by caller */

crimp_image*     result;
crimp_image*     image;

int px, py, lx, ly, ox, oy, pxi, pyi;

crimp_input (imageObj, image, grey32);

/*
 * Get the area of the input image to process.
 */

result = crimp_new_grey32_at (x, y, w, h);
ox = crimp_x (image);
oy = crimp_y (image);

/*
 * px, py are physical coordinates in the result, starting from 0. The
 * associated logical coordinates in the 2D plane are
 *
 *  lx = px + x(result)
 *  lx = py + y(result)
 *
 * And when we are inside an input its physical coordinates, from the logical
 * are
 *
 *  px' = lx - x(input)
 *  py' = ly - y(input)
 *
 * Important to note, we can compute all these directly as loop variables, as
 * they are all linearly related to each other.
 */

for (py = 0, ly = y, pyi = y - oy;
     py < h;
     py++, ly++, pyi++) {

    for (px = 0, lx = x, pxi = x - ox;
	 px < w;
	 px++, lx++, pxi++) {

	int inside = crimp_inside (image, lx, ly);

	/*
	 * The result depends on where we are relative to the input. Inside
	 * of the input we take the respective value of the pixel. Outside of
	 * the input we take BLACK as the value instead.
	 */

	int _v = inside ? GREY32 (image, pxi, pyi) : BLACK;
	
	GREY32 (result, px, py) = UNOP (_v);
    }
}

Tcl_SetObjResult(interp, crimp_new_image_obj (result));
return TCL_OK;

/* vim: set sts=4 sw=4 tw=80 et ft=c: */
/*
 * Local Variables:
 * mode: c
 * c-basic-offset: 4
 * fill-column: 78
 * End:
 */
