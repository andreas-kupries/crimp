crimp_image*     result;
crimp_image*     imageA;
crimp_image*     imageB;
int px, py, lx, ly, oxa, oya, oxb, oyb;
int pxa, pya, pxb, pyb;
crimp_geometry bb;

crimp_input (imageAObj, imageA, rgba);
crimp_input (imageBObj, imageB, rgba);

/*
 * Compute union area of the two images to process.
 * Note how the images do not have to match in size.
 */

crimp_rect_union (&imageA->geo, &imageB->geo, &bb);

result = crimp_new_rgba_at (bb.x, bb.y, bb.w, bb.h);
oxa = crimp_x (imageA);
oya = crimp_y (imageA);
oxb = crimp_x (imageB);
oyb = crimp_y (imageB);

/*
 * px, py are physical coordinates in the result, starting from 0.
 * The associated logical coordinates in the 2D plane are
 *  lx = px + x(result)
 *  lx = py + y(result)
 * And when we are inside an input its physical coordinates, from the logical are
 *  px' = lx - x(input)
 *  py' = ly - y(input)
 * Important to note, we can compute all these directly as loop variables, as
 * they are all linearly related to each other.
 */

#ifndef BINOP_POST
#define BINOP_POST(z) z
#endif

for (py = 0, ly = bb.y, pya = bb.y - oya, pyb = bb.y - oyb;
     py < bb.h;
     py++, ly++, pya++, pyb++) {

    for (px = 0, lx = bb.x, pxa = bb.x - oxa, pxb = bb.x - oxb;
	 px < bb.w;
	 px++, lx++, pxa++, pxb++) {

	int ina = crimp_inside (imageA, lx, ly);
	int inb = crimp_inside (imageB, lx, ly);

	/*
	 * The result depends on where we are relative to both input.
	 * Inside of each input we take the respective value of the
	 * pixel. Outside of an input we take BLACK as the value
	 * instead.
	 */

	int    a_r = ina ? R (imageA, pxa, pya) : BLACK;
	int    a_g = ina ? G (imageA, pxa, pya) : BLACK;
	int    a_b = ina ? B (imageA, pxa, pya) : BLACK;
	int    a_a = ina ? A (imageA, pxa, pya) : BLACK;
	int    b_r = inb ? R (imageB, pxb, pyb) : BLACK;
	int    b_g = inb ? G (imageB, pxb, pyb) : BLACK;
	int    b_b = inb ? B (imageB, pxb, pyb) : BLACK;
	int    b_a = inb ? A (imageB, pxb, pyb) : BLACK;
	
	R (result, px, py) = BINOP (a_r, b_r);
	G (result, px, py) = BINOP (a_g, b_g);
	B (result, px, py) = BINOP (a_b, b_b);
	A (result, px, py) = MAX   (a_a, b_a);
    }
}

#undef BINOP
#undef BINOP_POST

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
