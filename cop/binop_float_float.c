crimp_image*     result;
crimp_image*     imageA;
crimp_image*     imageB;
int x, y;
crimp_geometry bb;

crimp_input (imageAObj, imageA, float);
crimp_input (imageBObj, imageB, float);

/*
 * Compute union area of the two images to process.
 * Note how the images do not have to match in size.
 */

crimp_rect_union (&imageA->geo, &imageB->geo, &bb);

result = crimp_new_float_at (bb.x, bb.y, bb.w, bb.h);

/* x, y are physical coordinates, starting from 0.
 * The logical coordinates are
 *  x + x(image)
 *  y + y(image)
 */
for (y = 0; y < crimp_h (result); y++) {
    for (x = 0; x < crimp_w (result); x++) {

	int ina = crimp_inside (imageA, x + crimp_x (imageA), y + crimp_y (imageA));
	int inb = crimp_inside (imageB, x + crimp_x (imageB), y + crimp_y (imageB));

	/*
	 * The result depends on where we are relative to both input.  Inside
	 * of both the input pixels are properly combined. Inside of one, but
	 * not the other the other is assumed to be black. Outside both the
	 * result is made from assuming both as black.
	 */

	if (ina && inb) {
	    FLOATP (result, x, y) = BINOP (FLOATP (imageA, x, y), FLOATP (imageB, x, y));
	} else if (ina) {
	    FLOATP (result, x, y) = BINOP (FLOATP (imageA, x, y), BLACK);
	} else if (inb) {
	    FLOATP (result, x, y) = BINOP (BLACK, FLOATP (imageB, x, y));
	} else {
	    FLOATP (result, x, y) = BINOP (BLACK, BLACK);
	}
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
