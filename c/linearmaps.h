#include <stdlib.h>
#include "image.h"

extern int crimp_piecewise_linear_map_grey8_grey8(Tcl_Interp*,
    Tcl_Obj*, size_t, const unsigned char*, size_t, unsigned char*,
    size_t);
extern int crimp_piecewise_linear_map_grey8_grey16(Tcl_Interp*,
    Tcl_Obj*, size_t, const unsigned char*, size_t, unsigned short*,
    size_t);
extern int crimp_piecewise_linear_map_grey8_grey32(Tcl_Interp*,
    Tcl_Obj*, size_t, const unsigned char*, size_t, unsigned int*,
    size_t);
extern int crimp_piecewise_linear_map_grey8_float(Tcl_Interp*,
    Tcl_Obj*, size_t, const unsigned char*, size_t, float*,
    size_t);
extern int crimp_piecewise_linear_map_grey16_grey8(Tcl_Interp*,
    Tcl_Obj*, size_t, const unsigned short*, size_t, unsigned char*,
    size_t);
extern int crimp_piecewise_linear_map_grey16_grey16(Tcl_Interp*,
    Tcl_Obj*, size_t, const unsigned short*, size_t, unsigned short*,
    size_t);
extern int crimp_piecewise_linear_map_grey16_grey32(Tcl_Interp*,
    Tcl_Obj*, size_t, const unsigned short*, size_t, unsigned int*,
    size_t);
extern int crimp_piecewise_linear_map_grey16_float(Tcl_Interp*,
    Tcl_Obj*, size_t, const unsigned short*, size_t, float*,
    size_t);
extern int crimp_piecewise_linear_map_grey32_grey8(Tcl_Interp*,
    Tcl_Obj*, size_t, const unsigned int*, size_t, unsigned char*,
    size_t);
extern int crimp_piecewise_linear_map_grey32_grey16(Tcl_Interp*,
    Tcl_Obj*, size_t, const unsigned int*, size_t, unsigned short*,
    size_t);
extern int crimp_piecewise_linear_map_grey32_grey32(Tcl_Interp*,
    Tcl_Obj*, size_t, const unsigned int*, size_t, unsigned int*,
    size_t);
extern int crimp_piecewise_linear_map_grey32_float(Tcl_Interp*,
    Tcl_Obj*, size_t, const unsigned int*, size_t, float*,
    size_t);
extern int crimp_piecewise_linear_map_float_grey8(Tcl_Interp*,
    Tcl_Obj*, size_t, const float*, size_t, unsigned char*,
    size_t);
extern int crimp_piecewise_linear_map_float_grey16(Tcl_Interp*,
    Tcl_Obj*, size_t, const float*, size_t, unsigned short*,
    size_t);
extern int crimp_piecewise_linear_map_float_grey32(Tcl_Interp*,
    Tcl_Obj*, size_t, const float*, size_t, unsigned int*,
    size_t);
extern int crimp_piecewise_linear_map_float_float(Tcl_Interp*,
    Tcl_Obj*, size_t, const float*, size_t, float*,
    size_t);
