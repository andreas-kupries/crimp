crimp_image*     result;
crimp_image*     imageA;
crimp_image*     imageB;
int x, y;

crimp_input (imageAObj, imageA, float);
crimp_input (imageBObj, imageB, grey8);

if (!crimp_eq_dim (imageA, imageB)) {
    Tcl_SetResult(interp, "image dimensions do not match", TCL_STATIC);
    return TCL_ERROR;
}

result = crimp_new_like (imageA);

for (y = 0; y < result->h; y++) {
    for (x = 0; x < result->w; x++) {

	FLOATP (result, x, y) = BINOP (FLOATP (imageA, x, y), GREY8 (imageB, x, y));
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
