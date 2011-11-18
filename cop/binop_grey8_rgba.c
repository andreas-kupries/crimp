crimp_image*     result;
crimp_image*     imageA;
crimp_image*     imageB;
int x, y;

crimp_input (imageAObj, imageA, grey8);
crimp_input (imageBObj, imageB, rgba);

if (!crimp_eq_dim (imageA, imageB)) {
    Tcl_SetResult(interp, "image dimensions do not match", TCL_STATIC);
    return TCL_ERROR;
}

result = crimp_new_like (imageB);

for (y = 0; y < crimp_h (result); y++) {
    for (x = 0; x < crimp_w (result); x++) {

	R (result, x, y) = BINOP (GREY8 (imageA, x, y), R (imageB, x, y));
	G (result, x, y) = BINOP (GREY8 (imageA, x, y), G (imageB, x, y));
	B (result, x, y) = BINOP (GREY8 (imageA, x, y), B (imageB, x, y));
	A (result, x, y) =                              A (imageB, x, y);
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
