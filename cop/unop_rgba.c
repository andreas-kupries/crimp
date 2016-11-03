/* x, y, w, h - Parameters of the output image. Provided by caller */

crimp_image*     result;

int px, py, lx, ly, ox, oy, pxi, pyi;

/*
 * Get the area of the input image to process.
 */

result = crimp_new_rgba_at (x, y, w, h);
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

	int _r = inside ? R (image, pxi, pyi) : BLACK;
	int _g = inside ? G (image, pxi, pyi) : BLACK;
	int _b = inside ? B (image, pxi, pyi) : BLACK;
	int _a = inside ? A (image, pxi, pyi) : BLACK;
	
	R (result, px, py) = UNOP (_r);
	G (result, px, py) = UNOP (_g);
	B (result, px, py) = UNOP (_b);
	A (result, px, py) = _a;
    }
}

return result;

/* vim: set sts=4 sw=4 tw=80 et ft=c: */
/*
 * Local Variables:
 * mode: c
 * c-basic-offset: 4
 * fill-column: 78
 * End:
 */
