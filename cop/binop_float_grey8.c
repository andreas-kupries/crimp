crimp_image*     result;
crimp_image*     imageA;
crimp_image*     imageB;
int px, py, lx, ly, oxa, oya, oxb, oyb;
crimp_geometry bb;

crimp_input (imageAObj, imageA, float);
crimp_input (imageBObj, imageB, grey8);

/*
 * Compute union area of the two images to process.
 * Note how the images do not have to match in size.
 */

crimp_rect_union (&imageA->geo, &imageB->geo, &bb);

result = crimp_new_float_at (bb.x, bb.y, bb.w, bb.h);
oxa = crimp_x (imageA);
oya = crimp_y (imageA);
oxb = crimp_x (imageB);
oyb = crimp_y (imageB);

/*
 * x, y are physical coordinates in the result, starting from 0.
 * The associated logical coordinates in the 2D plane are
 *  lx = px + x(result)
 *  lx = py + y(result)
 * And when we are inside an input its physical coordinates, from the logical are
 *  px = lx - x(input)
 *  py = ly - y(input)
 */

for (py = 0; py < bb.h; py++) {
    for (px = 0; px < bb.w; px++) {

        int lx = px + bb.x;
        int ly = py + bb.y;

	int ina = crimp_inside (imageA, lx, ly);
	int inb = crimp_inside (imageB, lx, ly);

	/*
	 * The result depends on where we are relative to both input.
	 * Inside of each input we take the respective value of the
	 * pixel. Outside of an input we take BLACK as the value
	 * instead.
	 */

	double a_v = ina ? FLOATP (imageA, lx - oxa, ly - oya) : BLACK;
	int    b_v = inb ? GREY8 (imageB, lx - oxb, ly - oyb) : BLACK;
	
	FLOATP (result, px, py) = BINOP (a_v, b_v);
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
